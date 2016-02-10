Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
_ = require 'lodash'
EventEmitter = require 'events'

class ActionParser extends EventEmitter
	constructor: (@replay) ->
		EventEmitter.call(this)

		@player = @replay.player
		@opponent = @replay.opponent
		@mainPlayerId = @replay.mainPlayerId
		@history = @replay.history
		@entities = @replay.entities
		@turns = @replay.turns
		@getController = @replay.getController

	populateEntities: ->
		players = [@player, @opponent]

		#First add the missing card / entity info
		playerIndex = 0
		turnNumber = 1
		actionIndex = 0
		currentPlayer = players[playerIndex]

		# populate the entities
		for batch, i in @history
			for command, j in batch.commands
				## Populate relevant data for cards
				if (command[0] == 'receiveShowEntity')
					if (command[1].length > 0 && command[1][0].id && @entities[command[1][0].id]) 
						@entities[command[1][0].id].cardID = command[1][0].cardID
				if (command[0] == 'receiveEntity')
					if (command[1].length > 0 && command[1][0].id && !@entities[command[1][0].id]) 
						entity = new Entity(this)
						definition = _.cloneDeep command[1][0]
						@entities[definition.id] = entity
						# Entity not in the game yet
						definition.tags.ZONE = 6
						entity.update(definition)

		# Add intrinsic information, like whether the card is a secret
		for batch, i in @history
			for command, j in batch.commands
				if command[0] == 'receiveTagChange'
					# Adding information that this entity is a secret
					if command[1][0].tag == 'SECRET' and command[1][0].value == 1
						@entities[command[1][0].entity].tags[command[1][0].tag] = command[1][0].value
				if command[0] == 'receiveShowEntity'
					if command[1][0].tags.SECRET == 1
						@entities[command[1][0].id].tags.SECRET = 1


	parseActions: ->
		# Build the list of turns along with the history position of each
		@players = [@player, @opponent]
		@playerIndex = 0
		@turnNumber = 1
		@currentPlayer = @players[@playerIndex]
		for batch, i in @history
			for command, j in batch.commands

				@parseMulliganTurn batch, command
				@parseStartOfTurn batch, command
				@parseDrawCard batch, command

				# The actual actions
				if (command[0] == 'receiveAction')
					@currentTurnNumber = @turnNumber - 1
					if (@turns[@currentTurnNumber])

						@parseMulliganCards batch, command

						# Played a card
						if command[1][0].tags and command[1][0].attributes.type != '5'

							playedCard = -1

							excluded = false
							secret = false
							for tag in command[1][0].tags
								# Either in play or a secret
								if tag.tag == 'ZONE' and tag.value in [1, 7]
									playedCard = tag.entity
								if tag.tag == 'SECRET' and tag.value == 1
									secret = true
									publicSecret = command[1][0].attributes.type == '7' and @turns[@currentTurnNumber].activePlayer.id == @mainPlayerId
								# Those are effects that are added to a creature (like Cruel Taskmaster's bonus)
								# We don't want to treat them as a significant action, so we ignore them
								if tag.tag == 'ATTACHED'
									excluded = true

							if playedCard > -1 and !excluded
								action = {
									turn: @currentTurnNumber - 1
									timestamp: batch.timestamp
									type: ': '
									secret: secret
									publicSecret: publicSecret
									# If it's a secret, we want to know who put it in play
									data: @entities[playedCard]
									owner: @turns[@currentTurnNumber].activePlayer
									initialCommand: command[1][0]
									debugType: 'played card'
								}
								@addAction @currentTurnNumber, action

						# Secret revealed
						if command[1][0].attributes.entity and command[1][0].attributes.type == '5'
							entity = @entities[command[1][0].attributes.entity]
							if entity.tags.SECRET == 1
								console.log '\tyes', entity, command[1][0]
								action = {
									turn: @currentTurnNumber - 1
									# Used to make sure that revealed secrets occur after the action that triggered them
									timestamp: batch.timestamp + 0.01
									actionType: 'secret-revealed'
									data: entity
									# owner: @turns[currentTurnNumber].activePlayer
									initialCommand: command[1][0]
								}
								@addAction @currentTurnNumber, action


						# Card revealed
						# TODO: Don't add this when a spell is played, since another action already handles this
						# Also, don't reveal enchantments as "showentities"
						if command[1][0].showEntity and (command[1][0].attributes.type == '1' or (command[1][0].attributes.type != '3' and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)))

							#console.log 'considering action for entity ' + command[1][0].showEntity.id, command[1][0].showEntity.tags, command[1][0]
							playedCard = -1

							# Revealed entities can start in the PLAY zone
							if command[1][0].showEntity.tags
								for entityTag, tagValue of command[1][0].showEntity.tags
									#console.log '\t\tLooking at ', entityTag, tagValue
									if (entityTag == 'ZONE' && tagValue == 1)
										playedCard = command[1][0].showEntity.id

							# Don't consider mulligan choices for now
							if command[1][0].tags
								for tag in command[1][0].tags
									#console.log '\ttag', tag.tag, tag.value, tag
									if (tag.tag == 'ZONE' && tag.value == 1)
										playedCard = tag.entity

							if (playedCard > -1)
								#console.log '\tconsidering further'
								action = {
									turn: @currentTurnNumber - 1
									# index: actionIndex++
									timestamp: batch.timestamp
									type: ': '
									data: if @entities[command[1][0].showEntity.id] then @entities[command[1][0].showEntity.id] else command[1][0].showEntity
									owner: @turns[@currentTurnNumber].activePlayer
									debugType: 'showEntity'
									debug: command[1][0].showEntity
									initialCommand: command[1][0]
								}
								if (action.data)
									#console.log 'batch', i, batch
									#console.log '\tcommand', j, command
									#console.log '\t\tadding showEntity', command[1][0].showEntity, action
									@addAction @currentTurnNumber, action

						# Other trigger
						if command[1][0].tags and command[1][0].attributes.type == '5'

							playedCard = -1
							#if command[1][0].attributes.entity == '49'
								#console.log 'considering action', currentTurnNumber, command[1][0].tags, command

							excluded = false
							secret = false
							for tag in command[1][0].tags
								#console.log '\ttag', tag.tag, tag.value, tag
								# Either in play or a secret
								if tag.tag == 'ZONE' and tag.value in [1, 7]
									playedCard = tag.entity
								if tag.tag == 'SECRET' and tag.value == 1
									secret = true
								# Those are effects that are added to a creature (like Cruel Taskmaster's bonus)
								# We don't want to treat them as a significant action, so we ignore them
								if tag.tag == 'ATTACHED'
									excluded = true

							if playedCard > -1 and !excluded
								#console.log 'batch', i, batch
								#console.log '\tcommand', j, command
								#console.log '\t\tadding action to turn', currentTurnNumber, command[1][0].tags, command
								action = {
									turn: @currentTurnNumber - 1
									# index: actionIndex++
									timestamp: batch.timestamp
									type: ': '
									secret: secret
									data: @entities[playedCard]
									# It's a trigger, we log who caused it to trigger
									owner: command[1][0].attributes.entity
									initialCommand: command[1][0]
									debugType: 'played card from tigger'
								}
								@addAction @currentTurnNumber, action
								#console.log '\t\tadding action to turn', @turns[currentTurnNumber].actions[actionIndex]

						# Trigger with targets (or play that triggers some effects with targets, like Antique Healbot)
						if command[1][0].tags and command[1][0].attributes.type in ['3', '5'] and command[1][0].meta?.length > 0
							for meta in command[1][0].meta
								for info in meta.info
									# Don't add targeted triggers if parent is already targeted - we would log the same thing twice
									if meta.meta == 'TARGET' and meta.info?.length > 0 and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) != info.entity)
											action = {
												turn: @currentTurnNumber - 1
												# index: actionIndex++
												timestamp: batch.timestamp
												target: info.entity
												type: ': trigger '
												data: @entities[command[1][0].attributes.entity]
												owner: @getController(@entities[command[1][0].attributes.entity].tags.CONTROLLER) #@turns[currentTurnNumber].activePlayer
												initialCommand: command[1][0]
												debugType: 'trigger effect card'
											}
											@addAction @currentTurnNumber, action
											#console.log 'Added action', action

						# Deaths. Not really an action, but useful to see clearly what happens
						if command[1][0].tags and command[1][0].attributes.type == '6' 

							for tag in command[1][0].tags
								# Graveyard
								if (tag.tag == 'ZONE' && tag.value == 4)
									action = {
										turn: @currentTurnNumber - 1
										# index: actionIndex++
										timestamp: batch.timestamp
										type: ' died '
										owner: tag.entity
										initialCommand: command[1][0]
									}
									@addAction @currentTurnNumber, action

						# Attacked something
						if parseInt(command[1][0].attributes.target) > 0 and (command[1][0].attributes.type == '1' or !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)
							#console.log 'considering attack', command[1][0]
							action = {
								turn: @currentTurnNumber - 1
								# index: actionIndex++
								timestamp: batch.timestamp
								type: ': '
								actionType: 'attack'
								data: @entities[command[1][0].attributes.entity]
								owner: @turns[@currentTurnNumber].activePlayer
								target: command[1][0].attributes.target
								initialCommand: command[1][0]
								debugType: 'attack with complex conditions'
							}
							@addAction @currentTurnNumber, action
							#console.log '\t\tadding attack to turn', @turns[currentTurnNumber].actions[actionIndex]

						# Card powers. Maybe something more than just battlecries?
						# This also includes all effects from spells, which is too verbose. Don't add the action
						# if it results from a spell being played
						# 5 is to include triggering effects, like Piloted Shredder summoning of a minion
						if command[1][0].attributes.type in ['3' ,'5']

							# If parent action has a target, do nothing
							if !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0

								# Does it do damage?
								if command[1][0].tags
									dmg = 0
									target = undefined
									for tag in command[1][0].tags
										if (tag.tag == 'DAMAGE' && tag.value > 0)
											dmg = tag.value
											target = tag.entity

									if dmg > 0
										action = {
											turn: @currentTurnNumber - 1
											# index: actionIndex++
											timestamp: batch.timestamp
											prefix: '\t'
											type: ': '
											data: @entities[command[1][0].attributes.entity]
											owner: @turns[@currentTurnNumber].activePlayer
											# Don't store the full entity, because it's possible the target 
											# doesn't exist yet when parsing the replay
											# (it's the case for created tokens)
											#@entities[target]
											target: target
											initialCommand: command[1][0]
											debugType: 'power 3 dmg'
										}
										@addAction @currentTurnNumber, action

								# Don't include enchantments - we are already logging the fact that they are played
								if command[1][0].fullEntity and command[1][0].fullEntity.tags.CARDTYPE != 6

									# Also log what creates the new entities. Can be hero power 
									# HP are logged in a bit of a weird way, so we need to manually adjust their offset
									if command[1][0].parent
										for tag in command[1][0].parent.tags
											if (tag.tag == 'HEROPOWER_ACTIVATIONS_THIS_TURN' && tag.value > 0)
												command[1][0].indent = if command[1][0].indent > 1 then command[1][0].indent - 1 else undefined
												command[1][0].fullEntity.indent = if command[1][0].fullEntity.indent > 1 then command[1][0].fullEntity.indent - 1 else undefined
									
									action = {
										turn: @currentTurnNumber - 1
										# index: actionIndex++
										timestamp: batch.timestamp
										prefix: '\t'
										type: ': '
										data: @entities[command[1][0].attributes.entity]
										owner: @turns[@currentTurnNumber].activePlayer
										initialCommand: command[1][0]
										debugType: 'power 3 root'
									}
									@addAction @currentTurnNumber, action

									action = {
										turn: @currentTurnNumber - 1
										# index: actionIndex++
										timestamp: batch.timestamp
										prefix: '\t'
										creator: @entities[command[1][0].attributes.entity]
										type: ': '
										# This caused invoked minions from triggers to be detected as the minion who triggered them
										#data: @entities[command[1][0].attributes.entity]
										data: @entities[command[1][0].fullEntity.id]
										owner: @getController(command[1][0].fullEntity.tags.CONTROLLER) #@turns[currentTurnNumber].activePlayer
										# Don't store the full entity, because it's possible the target 
										# doesn't exist yet when parsing the replay
										# (it's the case for created tokens)
										#@entities[target]
										target: target
										initialCommand: command[1][0].fullEntity
										debugType: 'power 3'
										debug: @entities
									}
									@addAction @currentTurnNumber, action

								# Armor buff
								if command[1][0].tags
									armor = 0
									for tag in command[1][0].tags
										if tag.tag == 'ARMOR' and tag.value > 0
											armor = tag.value

									if armor > 0
										action = {
											turn: @currentTurnNumber - 1
											# index: actionIndex++
											timestamp: batch.timestamp
											prefix: '\t'
											type: ': '
											data: @entities[command[1][0].attributes.entity]
											owner: @getController(@entities[command[1][0].attributes.entity].tags.CONTROLLER)
											initialCommand: command[1][0]
											debugType: 'armor'
										}
										@addAction @currentTurnNumber, action

			#console.log @turns.length, 'game turns at position', @turns

		# Sort the actions chronologically
		tempTurnNumber = 1
		while @turns[tempTurnNumber]
			sortedActions = _.sortBy @turns[tempTurnNumber].actions, 'timestamp'
			@turns[tempTurnNumber].actions = sortedActions
			tempTurnNumber++


	addAction: (currentTurnNumber, action) ->
		# Actions are registered in batches in the XML (and the game), but we need to make sure that the parent 
		# actions happen before
		if action.initialCommand.parent and action.initialCommand.parent.timestamp == action.timestamp
			action.timestamp += 0.01
		@turns[currentTurnNumber].actions.push action



	# =======================
	# Specific actions
	# =======================
	parseMulliganTurn: (batch, command) ->
		# Mulligan
		# Add only one command for mulligan start, no need for both
		if (command[0] == 'receiveTagChange' && command[1][0].entity == 2 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
			@turns[@turnNumber] = {
				# historyPosition: i
				turn: 'Mulligan'
				playerMulligan: []
				opponentMulligan: []
				timestamp: batch.timestamp
				actions: []
			}
			@turns.length++
			@turnNumber++
			@currentPlayer = @players[++@playerIndex % 2]

		if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 3 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
			@currentPlayer = @players[++@playerIndex % 2]	


	parseStartOfTurn: (batch, command) ->
		# Start of turn
		if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 1 && command[1][0].tag == 'STEP' && command[1][0].value == 6)
			@turns[@turnNumber] = {
				# historyPosition: i
				turn: @turnNumber - 1
				timestamp: batch.timestamp
				actions: []
				activePlayer: @currentPlayer
			}
			@turns.length++
			@turnNumber++
			@currentPlayer = @players[++@playerIndex % 2]


	parseDrawCard: (batch, command) ->
		# Draw cards - 1 - Simply a card arriving in hand
		if command[0] == 'receiveTagChange' and command[1][0].tag == 'ZONE' and command[1][0].value == 3
			# Don't add card draws that are at the beginning of the game or during Mulligan
			if @currentTurnNumber >= 2
				currentCommand = command[1][0]
				while currentCommand.parent and currentCommand.entity not in ['2', '3']
					currentCommand = currentCommand.parent
				
				action = {
					turn: @currentTurnNumber
					timestamp: batch.timestamp
					actionType: 'card-draw'
					type: ' draws '
					data: @entities[command[1][0].entity]
					owner: @entities[currentCommand.attributes.entity]
					initialCommand: command[1][0]
				}
				@addAction @currentTurnNumber, action

		# Draw cards - 2 - The player draws a card, thus revealing a full entity
		if command[0] == 'receiveAction' and command[1][0].type = '5'
			# Don't add card draws that are at the beginning of the game or during Mulligan
			if @currentTurnNumber >= 2
				entity = command[1][0].showEntity || command[1][0].fullEntity
				if entity and entity.tags.ZONE == 3
					currentCommand = command[1][0]
					while currentCommand.parent and currentCommand.entity not in ['2', '3']
						currentCommand = currentCommand.parent
					
					action = {
						turn: @currentTurnNumber
						timestamp: batch.timestamp
						actionType: 'card-draw'
						type: ' draws '
						data: @entities[entity.id]
						owner: @entities[currentCommand.attributes.entity]
						initialCommand: command[1][0]
					}
					@addAction @currentTurnNumber, action


	parseMulliganCards: (batch, command) ->
		# Mulligan
		if command[1][0].attributes.type == '5' and @currentTurnNumber == 1 and command[1][0].hideEntities
			@turns[@currentTurnNumber].playerMulligan = command[1][0].hideEntities

		# Mulligan opponent
		if command[1][0].attributes.type == '5' and @currentTurnNumber == 1 and command[1][0].attributes.entity != @mainPlayerId
			mulliganed = []
			for tag in command[1][0].tags
				if tag.tag == 'ZONE' and tag.value == 2
					@turns[@currentTurnNumber].opponentMulligan.push tag.entity


module.exports = ActionParser
