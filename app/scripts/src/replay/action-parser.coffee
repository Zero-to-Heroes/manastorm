Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
_ = require 'lodash'
EventEmitter = require 'events'

tsToSeconds = (ts) ->
	parts = ts?.split?(':')

	if !parts
		return null

	hours = parseInt(parts[0]) * 60 * 60
	minutes = parseInt(parts[1]) * 60
	seconds = parseFloat(parts[2])

	return hours + minutes + seconds

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

						# We need to keep this one high priority, as it often has the same timestamp as its consequence
						@parseSecretRevealed batch, command[1][0]
						@parseMulliganCards batch, command[1][0]
						@parseCardPlayedFromHand batch, command[1][0]
						@parseHeroPowerUsed batch, command[1][0]
						@parseSecretPlayedFromHand batch, command[1][0]
						@parseAttacks batch, command[1][0]
						@parsePowerEffects batch, command[1][0]
						@parseDeaths batch, command[1][0]
						@parseDiscovers batch, command[1][0]
						@parseSummons batch, command[1][0]
						@parseEquipEffect batch, command[1][0]
						@parseTriggerFullEntityCreation batch, command[1][0]
						@parseTriggerPutSecretInPlay batch, command[1][0]


						# Played a card Legacy
						# if command[1][0].tags and command[1][0].attributes.type not in ['5', '7']

						# 	playedCard = -1

						# 	excluded = false
						# 	secret = false
						# 	for tag in command[1][0].tags
						# 		# Either in play or a secret
						# 		if tag.tag == 'ZONE' and tag.value in [1, 7]
						# 			playedCard = tag.entity
						# 		if tag.tag == 'SECRET' and tag.value == 1
						# 			secret = true
						# 			publicSecret = command[1][0].attributes.type == '7' and @turns[@currentTurnNumber].activePlayer.id == @mainPlayerId
						# 		# Those are effects that are added to a creature (like Cruel Taskmaster's bonus)
						# 		# We don't want to treat them as a significant action, so we ignore them
						# 		if tag.tag == 'ATTACHED'
						# 			excluded = true

						# 	if playedCard > -1 and !excluded
						# 		action = {
						# 			turn: @currentTurnNumber - 1
						# 			timestamp: batch.timestamp
						# 			type: ': '
						# 			secret: secret
						# 			publicSecret: publicSecret
						# 			# If it's a secret, we want to know who put it in play
						# 			data: @entities[playedCard]
						# 			owner: @turns[@currentTurnNumber].activePlayer
						# 			initialCommand: command[1][0]
						# 			debugType: 'played card'
						# 		}
						# 		@addAction @currentTurnNumber, action

						# Secret revealed
						# if command[1][0].attributes.entity and command[1][0].attributes.type == '5'
						# 	entity = @entities[command[1][0].attributes.entity]
						# 	if entity.tags.SECRET == 1
						# 		console.log '\tyes', entity, command[1][0]
						# 		action = {
						# 			turn: @currentTurnNumber - 1
						# 			# Used to make sure that revealed secrets occur after the action that triggered them
						# 			timestamp: batch.timestamp + 0.01
						# 			actionType: 'secret-revealed'
						# 			data: entity
						# 			# owner: @turns[currentTurnNumber].activePlayer
						# 			initialCommand: command[1][0]
						# 		}
						# 		@addAction @currentTurnNumber, action


						# Card revealed
						# TODO: Don't add this when a spell is played, since another action already handles this
						# Also, don't reveal enchantments as "showentities"
						# 7 case is handled by the "playing from hand" action below
						# if command[1][0].showEntity and (command[1][0].attributes.type == '1' or (command[1][0].attributes.type not in ['3', '7'] and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)))

						# 	#console.log 'considering action for entity ' + command[1][0].showEntity.id, command[1][0].showEntity.tags, command[1][0]
						# 	playedCard = -1

						# 	# Revealed entities can start in the PLAY zone
						# 	if command[1][0].showEntity.tags
						# 		for entityTag, tagValue of command[1][0].showEntity.tags
						# 			#console.log '\t\tLooking at ', entityTag, tagValue
						# 			if (entityTag == 'ZONE' && tagValue == 1)
						# 				playedCard = command[1][0].showEntity.id

						# 	# Don't consider mulligan choices for now
						# 	if command[1][0].tags
						# 		for tag in command[1][0].tags
						# 			#console.log '\ttag', tag.tag, tag.value, tag
						# 			if (tag.tag == 'ZONE' && tag.value == 1)
						# 				playedCard = tag.entity

						# 	if (playedCard > -1)
						# 		#console.log '\tconsidering further'
						# 		action = {
						# 			turn: @currentTurnNumber - 1
						# 			# index: actionIndex++
						# 			timestamp: batch.timestamp
						# 			type: ': '
						# 			data: if @entities[command[1][0].showEntity.id] then @entities[command[1][0].showEntity.id] else command[1][0].showEntity
						# 			owner: @turns[@currentTurnNumber].activePlayer
						# 			debugType: 'showEntity'
						# 			debug: command[1][0].showEntity
						# 			initialCommand: command[1][0]
						# 		}
						# 		if (action.data)
						# 			#console.log 'batch', i, batch
						# 			#console.log '\tcommand', j, command
						# 			#console.log '\t\tadding showEntity', command[1][0].showEntity, action
						# 			@addAction @currentTurnNumber, action

						# Other trigger
						# if command[1][0].tags and command[1][0].attributes.type == '5'

						# 	playedCard = -1
						# 	#if command[1][0].attributes.entity == '49'
						# 		#console.log 'considering action', currentTurnNumber, command[1][0].tags, command

						# 	excluded = false
						# 	secret = false
						# 	for tag in command[1][0].tags
						# 		#console.log '\ttag', tag.tag, tag.value, tag
						# 		# Either in play or a secret
						# 		if tag.tag == 'ZONE' and tag.value in [1, 7]
						# 			playedCard = tag.entity
						# 		if tag.tag == 'SECRET' and tag.value == 1
						# 			secret = true
						# 		# Those are effects that are added to a creature (like Cruel Taskmaster's bonus)
						# 		# We don't want to treat them as a significant action, so we ignore them
						# 		if tag.tag == 'ATTACHED'
						# 			excluded = true

						# 	if playedCard > -1 and !excluded
						# 		#console.log 'batch', i, batch
						# 		#console.log '\tcommand', j, command
						# 		#console.log '\t\tadding action to turn', currentTurnNumber, command[1][0].tags, command
						# 		action = {
						# 			turn: @currentTurnNumber - 1
						# 			# index: actionIndex++
						# 			timestamp: batch.timestamp
						# 			type: ': '
						# 			secret: secret
						# 			data: @entities[playedCard]
						# 			# It's a trigger, we log who caused it to trigger
						# 			owner: command[1][0].attributes.entity
						# 			initialCommand: command[1][0]
						# 			debugType: 'played card from tigger'
						# 		}
						# 		@addAction @currentTurnNumber, action
						# 		#console.log '\t\tadding action to turn', @turns[currentTurnNumber].actions[actionIndex]

						# Trigger with targets (or play that triggers some effects with targets, like Antique Healbot)
						# if command[1][0].tags and command[1][0].attributes.type in ['5'] and command[1][0].meta?.length > 0
						# 	for meta in command[1][0].meta
						# 		for info in meta.info
						# 			# Don't add targeted triggers if parent is already targeted - we would log the same thing twice
						# 			if meta.meta == 'TARGET' and meta.info?.length > 0 and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) != info.entity)
						# 					action = {
						# 						turn: @currentTurnNumber - 1
						# 						# index: actionIndex++
						# 						timestamp: batch.timestamp
						# 						target: info.entity
						# 						type: ': trigger '
						# 						data: @entities[command[1][0].attributes.entity]
						# 						owner: @getController(@entities[command[1][0].attributes.entity].tags.CONTROLLER) #@turns[currentTurnNumber].activePlayer
						# 						initialCommand: command[1][0]
						# 						debugType: 'trigger effect card'
						# 					}
						# 					@addAction @currentTurnNumber, action
						# 					#console.log 'Added action', action

						

						# Attacked something
						# command[1][0].attributes.type == '1' is handled in the new version
						# if parseInt(command[1][0].attributes.target) > 0 and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)
						# 	#console.log 'considering attack', command[1][0]
						# 	action = {
						# 		turn: @currentTurnNumber - 1
						# 		# index: actionIndex++
						# 		timestamp: batch.timestamp
						# 		type: ': '
						# 		actionType: 'attack'
						# 		data: @entities[command[1][0].attributes.entity]
						# 		owner: @turns[@currentTurnNumber].activePlayer
						# 		target: command[1][0].attributes.target
						# 		initialCommand: command[1][0]
						# 		debugType: 'attack with complex conditions'
						# 	}
						# 	@addAction @currentTurnNumber, action
						# 	#console.log '\t\tadding attack to turn', @turns[currentTurnNumber].actions[actionIndex]

						# Card powers. Maybe something more than just battlecries?
						# This also includes all effects from spells, which is too verbose. Don't add the action
						# if it results from a spell being played
						# 5 is to include triggering effects, like Piloted Shredder summoning of a minion
						# if command[1][0].attributes.type in ['3' ,'5']

						# 	# If parent action has a target, do nothing
						# 	if !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0

						# 		# Does it do damage?
						# 		if command[1][0].tags
						# 			dmg = 0
						# 			target = undefined
						# 			for tag in command[1][0].tags
						# 				if (tag.tag == 'DAMAGE' && tag.value > 0)
						# 					dmg = tag.value
						# 					target = tag.entity

						# 			# We now handle this in a different case
						# 			if dmg > 0 and command[1][0].attributes.type == '5'
						# 				action = {
						# 					turn: @currentTurnNumber - 1
						# 					# index: actionIndex++
						# 					timestamp: batch.timestamp
						# 					prefix: '\t'
						# 					type: ': '
						# 					data: @entities[command[1][0].attributes.entity]
						# 					owner: @turns[@currentTurnNumber].activePlayer
						# 					# Don't store the full entity, because it's possible the target 
						# 					# doesn't exist yet when parsing the replay
						# 					# (it's the case for created tokens)
						# 					#@entities[target]
						# 					target: target
						# 					initialCommand: command[1][0]
						# 					debugType: 'power 3 dmg'
						# 				}
						# 				@addAction @currentTurnNumber, action

								# Don't include enchantments - we are already logging the fact that they are played
								# Don't include discover, handled elsewhere (in the new extracted methods)
								# if command[1][0].fullEntity and command[1][0].fullEntity.tags.CARDTYPE != 6 and !(command[1][0].attributes.type == '3' and command.fullEntities?.length == 3)

								# 	# Also log what creates the new entities. Can be hero power 
								# 	# HP are logged in a bit of a weird way, so we need to manually adjust their offset
								# 	if command[1][0].parent
								# 		for tag in command[1][0].parent.tags
								# 			if (tag.tag == 'HEROPOWER_ACTIVATIONS_THIS_TURN' && tag.value > 0)
								# 				command[1][0].indent = if command[1][0].indent > 1 then command[1][0].indent - 1 else undefined
								# 				command[1][0].fullEntity.indent = if command[1][0].fullEntity.indent > 1 then command[1][0].fullEntity.indent - 1 else undefined
									
								# 	action = {
								# 		turn: @currentTurnNumber - 1
								# 		# index: actionIndex++
								# 		timestamp: batch.timestamp
								# 		prefix: '\t'
								# 		type: ': '
								# 		data: @entities[command[1][0].attributes.entity]
								# 		owner: @turns[@currentTurnNumber].activePlayer
								# 		initialCommand: command[1][0]
								# 		debugType: 'power 3 root'
								# 	}
								# 	@addAction @currentTurnNumber, action

								# 	action = {
								# 		turn: @currentTurnNumber - 1
								# 		# index: actionIndex++
								# 		timestamp: batch.timestamp
								# 		prefix: '\t'
								# 		creator: @entities[command[1][0].attributes.entity]
								# 		type: ': '
								# 		# This caused invoked minions from triggers to be detected as the minion who triggered them
								# 		#data: @entities[command[1][0].attributes.entity]
								# 		data: @entities[command[1][0].fullEntity.id]
								# 		owner: @getController(command[1][0].fullEntity.tags.CONTROLLER) #@turns[currentTurnNumber].activePlayer
								# 		# Don't store the full entity, because it's possible the target 
								# 		# doesn't exist yet when parsing the replay
								# 		# (it's the case for created tokens)
								# 		#@entities[target]
								# 		target: target
								# 		initialCommand: command[1][0].fullEntity
								# 		debugType: 'power 3'
								# 		debug: @entities
								# 	}
								# 	@addAction @currentTurnNumber, action

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
		# if action.initialCommand.parent and action.initialCommand.parent.timestamp == action.timestamp
			# action.timestamp += 0.01
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

		currentCommand = command[1][0]

		# Draw cards - 1 - Simply a card arriving in hand
		if command[0] == 'receiveTagChange' and command[1][0].tag == 'ZONE' and command[1][0].value == 3
			# Don't add card draws that are at the beginning of the game or during Mulligan
			if @currentTurnNumber >= 2
				while currentCommand.parent and currentCommand.entity not in ['2', '3']
					currentCommand = currentCommand.parent

				# When a card is played that makes you draw, the "root" action isn't an action owned by the player, 
				# but by the card itself. So we need to find out who that card controller is
				ownerId = currentCommand.attributes.entity
				if ownerId not in ['2', '3']
					owner = @getController(@entities[ownerId].tags.CONTROLLER)
				else
					owner = @entities[ownerId]
				
				action = {
					turn: @currentTurnNumber
					timestamp: batch.timestamp
					actionType: 'card-draw'
					type: 'from tag change'
					data: @entities[command[1][0].entity]
					mainAction: command[1][0].parent?.parent # It's a tag change, so we are interesting in the enclosing action
					owner: owner
					initialCommand: command[1][0]
				}
				@addAction @currentTurnNumber, action

		# Draw cards - 2 - The player draws a card, thus revealing a full entity
		if command[0] == 'receiveAction'
			# Don't add card draws that are at the beginning of the game or during Mulligan
			if @currentTurnNumber >= 2
				while currentCommand.parent and currentCommand.entity not in ['2', '3']
					currentCommand = currentCommand.parent

				# When a card is played that makes you draw, the "root" action isn't an action owned by the player, 
				# but by the card itself. So we need to find out who that card controller is
				ownerId = currentCommand.attributes.entity
				if ownerId not in ['2', '3']
					owner = @getController(@entities[ownerId].tags.CONTROLLER)
				else
					owner = @entities[ownerId]

				entity = command[1][0].showEntity || command[1][0].fullEntity
				if entity and entity.tags.ZONE == 3
					currentCommand = command[1][0]
					while currentCommand.parent and currentCommand.entity not in ['2', '3']
						currentCommand = currentCommand.parent
					
					action = {
						turn: @currentTurnNumber
						timestamp: batch.timestamp
						actionType: 'card-draw'
						type: 'from action'
						data: @entities[entity.id]
						mainAction: command[1][0].parent
						owner: owner
						initialCommand: command[1][0]
					}
					@addAction @currentTurnNumber, action


	parseMulliganCards: (batch, command) ->
		# Mulligan
		if command.attributes.type == '5' and @currentTurnNumber == 1 and command.hideEntities
			@turns[@currentTurnNumber].playerMulligan = command.hideEntities

		# Mulligan opponent
		if command.attributes.type == '5' and @currentTurnNumber == 1 and command.attributes.entity != @mainPlayerId
			mulliganed = []
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value == 2
					@turns[@currentTurnNumber].opponentMulligan.push tag.entity


	# Not secrets
	parseCardPlayedFromHand: (batch, command) ->
		if command.attributes.type == '7'

			# Check that the entity was in our hand before
			entity = @entities[command.attributes.entity]

			if command.attributes.entity == '6'
				console.log 'Play Dire Wold command', entity, command

			playedCard = -1
			# The case of a ShowEntity command when the card was already known - basically 
			# when we play our own card. In that case, the tags are already known, and 
			# tag changes are the only things we care about
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value == 1
					# Check that we are not revealing an enchantmnent
					if @entities[tag.entity].tags.CARDTYPE != 6
						playedCard = tag.entity

			# The case of a ShowEntity (or FullEntity) when we didn't previously know the 
			# card. In that case, a ShowEntity (or FullEntity) element is created that contains
			# the tag with the proper zone
			if playedCard < 0 and command.showEntity
				if command.showEntity.tags.ZONE == 1
					playedCard = command.showEntity.id

			# Possibly check that the card was in hand before being in play?
			if playedCard > -1
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
					actionType: 'played-card-from-hand'
					data: @entities[playedCard]
					owner: @turns[@currentTurnNumber].activePlayer
					initialCommand: command
				}
				# console.log '\tAnd it is a valid play', action
				@addAction @currentTurnNumber, action

	
	

	parseHeroPowerUsed: (batch, command) ->
		if command.attributes.type == '7'

			# Check that the entity was in our hand before
			entity = @entities[command.attributes.entity]
			# console.log 'Considering play of', entity, command

			if entity.tags.CARDTYPE == 10
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
					actionType: 'hero-power'
					data: entity
					owner: @getController(entity.tags.CONTROLLER)
					initialCommand: command
				}
				# console.log '\tAnd it is a valid play', action
				@addAction @currentTurnNumber, action

	parseSecretPlayedFromHand: (batch, command) ->
		if command.attributes.type == '7'

			playedCard = -1
			secret = false
			for tag in command.tags
				# Either in play or a secret
				if tag.tag == 'ZONE' and tag.value == 7
					playedCard = tag.entity
				if tag.tag == 'SECRET' and tag.value == 1
					secret = true

			if playedCard > -1 and secret
				entity = @entities[playedCard]
				owner = @getController(entity.tags.CONTROLLER) 
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
					actionType: 'played-secret-from-hand'
					# If it's a secret, we want to know who put it in play
					data: entity
					owner: owner
					initialCommand: command
				}
				@addAction @currentTurnNumber, action



	# Damage, healing and jousts
	parsePowerEffects: (batch, command) ->
		if command.attributes.type in ['3', '5'] and command.meta?.length > 0
			# If the entity that triggers the power is something that just did an action, we don't log that again
			if command.parent?.attributes?.entity == command.attributes.entity
				sameOwnerAsParent = true

			# Is the effect triggered in response to another play?
			if command.parent
				mainAction = command.parent

			for meta in command.meta
				for info in meta.info

					# The power dealt some damage
					if meta.meta == 'DAMAGE'
						action = {
							turn: @currentTurnNumber - 1
							timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp
							target: info.entity
							amount: meta.data
							mainAction: mainAction
							sameOwnerAsParent: sameOwnerAsParent
							actionType: 'power-damage'
							data: @entities[command.attributes.entity]
							owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
							initialCommand: command
						}
						# console.log 'creating power-target', action, meta
						@addAction @currentTurnNumber, action

					# The power simply targets something else
					if meta.meta == 'TARGET'
						action = {
							turn: @currentTurnNumber - 1
							timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp
							target: info.entity
							mainAction: mainAction
							sameOwnerAsParent: sameOwnerAsParent
							actionType: 'power-target'
							data: @entities[command.attributes.entity]
							owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
							initialCommand: command
						}
						@addAction @currentTurnNumber, action


	parseTriggerPutSecretInPlay: (batch, command) ->
		if command.attributes.type in ['3', '5'] 
			secretsPutInPlay = []
			if command.tags
				for tag in command.tags
					if tag.tag == 'ZONE' and tag.value == 7
						entity = @entities[tag.entity]
						# if !entity
						# 	entity = {
						# 		id: tag
						# 		etc
						# 	}
						secretsPutInPlay.push entity

				if secretsPutInPlay.length > 0
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
						secrets: secretsPutInPlay
						mainAction: command.parent
						actionType: 'trigger-secret-play'
						data: @entities[command.attributes.entity]
						owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
						initialCommand: command
					}
					@addAction @currentTurnNumber, action

	# The other effects, like battlecry, echoing ooze duplication, etc.
	parseTriggerFullEntityCreation: (batch, command) ->
		if command.attributes.type in ['5'] 
			# Trigger that creates an entity
			if command.fullEntities?.length > 0
				fullEntities = _.filter(command.fullEntities, (entity) -> entity.tags.ZONE == 1 )
				if fullEntities?.length > 0
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
						actionType: 'trigger-fullentity'
						data: @entities[command.attributes.entity]
						owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
						newEntities: fullEntities
						initialCommand: command
					}
					@addAction @currentTurnNumber, action


	parseAttacks: (batch, command) ->
		if command.attributes.type == '1'
			#console.log 'considering attack', command
			action = {
				turn: @currentTurnNumber - 1
				timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
				actionType: 'attack'
				data: @entities[command.attributes.entity]
				owner: @turns[@currentTurnNumber].activePlayer
				target: command.attributes.target
				initialCommand: command
			}
			@addAction @currentTurnNumber, action

			# TODO: log the damage done

	parseDeaths: (batch, command) ->
		if command.tags and command.attributes.type == '6' 
			for tag in command.tags
				# Graveyard
				if tag.tag == 'ZONE' and tag.value == 4
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
						actionType: 'minion-death'
						data: tag.entity
						initialCommand: command
					}
					@addAction @currentTurnNumber, action


	parseDiscovers: (batch, command) ->
		# Always discover 3 cards
		if command.attributes.type == '3' and command.fullEntities?.length == 3
			# Check that each of them is in the SETASIDE zone
			isDiscover = true
			choices = []
			for entity in command.fullEntities
				choices.push entity
				if entity.tags.ZONE != 6
					isDiscover = false

			if isDiscover
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
					actionType: 'discover'
					data: @entities[command.attributes.entity]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					choices: choices
					initialCommand: command
				}
				command.isDiscover = true
				console.log 'adding discover action', action
				@addAction @currentTurnNumber, action


	parseSummons: (batch, command) ->
		# A power that creates new entities - minions
		if command.attributes.type == '3' and command.fullEntities?.length > 0
			for entity in command.fullEntities
				# Only care about summons here, which are entities that come in play directly
				# And summons only concerns minions - specific handlers take care of the rest
				if entity.tags.ZONE == 1 and entity.tags.CARDTYPE == 4
					# Is the effect triggered in response to another play?
					if command.parent
						mainAction = command.parent

					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
						actionType: 'summon-minion'
						data: entity
						owner: @getController(entity.tags.CONTROLLER)
						mainAction: mainAction
						initialCommand: command
					}
					@addAction @currentTurnNumber, action

	parseEquipEffect: (batch, command) ->
		# A power that creates new entities - weapons
		if command.attributes.type == '3' and command.fullEntities?.length > 0
			for entity in command.fullEntities
				# Only care about summons here, which are entities that come in play directly
				# And summons only concerns minions - specific handlers take care of the rest
				if entity.tags.ZONE == 1 and entity.tags.CARDTYPE == 7
					# Is the effect triggered in response to another play?
					if command.parent
						mainAction = command.parent

					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
						actionType: 'summon-weapon'
						data: entity
						owner: @getController(entity.tags.CONTROLLER)
						mainAction: mainAction
						initialCommand: command
					}
					@addAction @currentTurnNumber, action

	parseSecretRevealed: (batch, command) ->
		if command.attributes.type == '5'
			entity = @entities[command.attributes.entity]
			if entity?.tags?.SECRET == 1
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
					actionType: 'secret-revealed'
					data: entity
					initialCommand: command
				}
				@addAction @currentTurnNumber, action



module.exports = ActionParser
