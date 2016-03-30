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
		@cardUtils = @replay.cardUtils

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

		# Sometimes card type isn't precised
		for k,v of @entities
			card = @cardUtils.getCard(v.cardID)
			# console.log 'getting card', v.cardID, card
			if card?.type is 'Spell' and !v.tags.CARDTYPE
				v.tags.CARDTYPE = 5


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
						@parseDiscovers batch, command[1][0]
						@parsePowerEffects batch, command[1][0]
						@parseDeaths batch, command[1][0]
						@parseSummons batch, command[1][0]
						@parseEquipEffect batch, command[1][0]
						@parseTriggerFullEntityCreation batch, command[1][0]
						@parseTriggerPutSecretInPlay batch, command[1][0]
						@parseNewHeroPower batch, command[1][0]


				if (command[0] == 'receiveTagChange')
					@currentTurnNumber = @turnNumber - 1
					if (@turns[@currentTurnNumber])

						@parseFatigueDamage batch, command[1][0]

				# Keeping that for last in order to make some non-timestamped action more coherent (like losing life from life 
				# tap before drawing the card)
				@parseDrawCard batch, command

		# Sort the actions chronologically
		tempTurnNumber = 1
		while @turns[tempTurnNumber]
			# First remove actions that we don't want to consider, but that we didn't have enough information
			# to not log first (typically the power-target that targets self on a discover action)
			filterFunction = @filterAction
			filteredActions = _.filter @turns[tempTurnNumber].actions, filterFunction
			# console.log 'sorting actions for turn', tempTurnNumber
			sortedActions = _.sortBy filteredActions, 'index'
			sortedActions = _.sortBy sortedActions, 'timestamp'
			@turns[tempTurnNumber].actions = sortedActions
			# console.log '\tsorted', @turns[tempTurnNumber].actions
			tempTurnNumber++

	filterAction: (action) ->
		# console.log 'filtering action', action
		# if action.actionType == 'power-target' and action.initialCommand?.associatedAction?.actionType == 'discover'
		# 	console.log 'filtering out action', action
		# 	return false
		return true


	addAction: (currentTurnNumber, action) ->
		# Keep the initial game order
		action.index = action.index || action.initialCommand.index
		action.initialCommand.associatedAction = action
		@turns[currentTurnNumber].actions.push action



	# =======================
	# Specific actions
	# =======================
	parseMulliganTurn: (batch, command) ->
		# Mulligan
		# Add only one command for mulligan start, no need for both
		if (command[0] == 'receiveTagChange' && command[1][0].entity == 2 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
			@turns[@turnNumber] = {
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
				# ownerId = currentCommand.attributes.entity
				ownerId = command[1][0].entity
				if ownerId not in ['2', '3']
					owner = @getController(@entities[ownerId].tags.CONTROLLER)
				else
					owner = @entities[ownerId]

				lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
				if lastAction?.actionType is 'card-draw' and lastAction.owner.id is owner.id
					lastAction.data.push command[1][0].entity
				else
					action = {
						turn: @currentTurnNumber
						timestamp: batch.timestamp
						actionType: 'card-draw'
						type: 'from tag change'
						data: [command[1][0].entity]
						mainAction: command[1][0].parent?.parent # It's a tag change, so we are interesting in the enclosing action
						owner: owner
						initialCommand: command[1][0]
						debug_lastAction: lastAction
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

				entities = command[1][0].showEntities || command[1][0].fullEntities
				if entities
					currentCommand = command[1][0]
					while currentCommand.parent and currentCommand.entity not in ['2', '3']
						currentCommand = currentCommand.parent
					
					for entity in entities
						if entity.tags.ZONE == 3
							lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
							if lastAction?.actionType is 'card-draw' and lastAction.owner.id is parseInt(owner.id)
								lastAction.data.push entity.id
							else
								action = {
									turn: @currentTurnNumber
									timestamp: batch.timestamp
									actionType: 'card-draw'
									type: 'from action'
									data: [entity.id]
									mainAction: command[1][0].parent
									owner: owner
									initialCommand: command[1][0]
									debug_lastAction: lastAction
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

	parseNewHeroPower: (batch, command) ->
		if command.attributes.type in ['3', '5'] and command.tags
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value == 1
					entity = @entities[tag.entity]
					card = @replay.cardUtils.getCard(entity['cardID'])
					if card.type == 'Hero Power'
						action = {
							turn: @currentTurnNumber - 1
							timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
							actionType: 'new-hero-power'
							data: entity
							owner: @getController(entity.tags.CONTROLLER)
							initialCommand: command
						}
						# console.log 'receving a new hero power', action
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
		if command.attributes.type in ['3', '5'] 

			if command.meta?.length > 0
				# If the entity that triggers the power is something that just did an action, we don't log that again
				sameOwnerAsParent = (command.parent?.attributes?.entity == command.attributes.entity)

				# Is the effect triggered in response to another play?
				if command.parent
					mainAction = command.parent

				for meta in command.meta
					if !meta.info
						continue
						
					for info in meta.info

						subAction = false

						# The power simply targets something else
						if meta.meta == 'TARGET'
							if mainAction?.actions 
								for action in mainAction.actions
									# If the same source deals the same amount of damage, we group all of that together
									if action.actionType is 'power-target' and action.data.id is parseInt(command.attributes.entity)
										action.target.push info.entity
										subAction = true

							# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
							lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
							if !mainAction and lastAction?.actionType is 'power-target' and lastAction.data.id is parseInt(command.attributes.entity)
								# console.log 'previous action is target, dont add this one', lastAction, command, lastAction.actionType, lastAction.actionType is 'power-target'
								lastAction.target.push info.entity
								subAction = true

							if !subAction and !(lastAction?.actionType is 'discover')
								action = {
									turn: @currentTurnNumber - 1
									timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp
									index: meta.index
									target: [info.entity]
									mainAction: mainAction
									sameOwnerAsParent: sameOwnerAsParent
									actionType: 'power-target'
									data: @entities[command.attributes.entity]
									owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
									initialCommand: command
									previousAction: lastAction
								}
								# console.log '\tparsing target action', action, command, command.isDiscover
								if mainAction
									mainAction.actions = mainAction.actions or []
									mainAction.actions.push action
								@addAction @currentTurnNumber, action
								
						# The power dealt some damage
						if meta.meta == 'DAMAGE'
							if mainAction?.actions 
								for action in mainAction.actions
									# If the same source deals the same amount of damage, we group all of that together
									if action.actionType is 'power-damage' and action.data.id is parseInt(command.attributes.entity) and action.amount is meta.data
										action.target.push info.entity
										subAction = true
										if lastAction?.actionType is 'power-target'
											@turns[@currentTurnNumber].actions.pop()

							# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
							lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
							if !mainAction and lastAction?.actionType is 'power-damage' and lastAction.data.id is parseInt(command.attributes.entity) and lastAction.amount is meta.data
								console.log 'previous action is damage, dont add this one', lastAction, command, lastAction.actionType, lastAction.actionType is 'power-damage'
								lastAction.target.push info.entity
								subAction = true
								if lastAction?.actionType is 'power-target'
									@turns[@currentTurnNumber].actions.pop()
							
							if !subAction
								action = {
									turn: @currentTurnNumber - 1
									timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp
									index: meta.index
									target: [info.entity]
									# Renaming in hsreplay 1.1
									amount: meta.data
									mainAction: mainAction
									sameOwnerAsParent: sameOwnerAsParent
									actionType: 'power-damage'
									data: @entities[command.attributes.entity]
									owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
									initialCommand: command
								}
								if mainAction
									mainAction.actions = mainAction.actions or []
									mainAction.actions.push action

								# If the preceding action is a "targeting" one, we remove it, as the info would be redundent
								if lastAction?.actionType is 'power-target'
									@turns[@currentTurnNumber].actions.pop()

								@addAction @currentTurnNumber, action

						# The power healed someone
						if meta.meta == 'HEALING'
							if mainAction?.actions 
								for action in mainAction.actions
									# If the same source deals the same amount of damage, we group all of that together
									if action.actionType is 'power-healing' and action.data.id is parseInt(command.attributes.entity) and action.amount is meta.data
										action.target.push info.entity
										subAction = true
										
							# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
							lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
							if !mainAction and lastAction?.actionType is 'power-healing' and lastAction.data.id is parseInt(command.attributes.entity) and lastAction.amount is meta.data
								lastAction.target.push info.entity
								subAction = true

							if !subAction
								action = {
									turn: @currentTurnNumber - 1
									timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp
									index: meta.index
									target: [info.entity]
									# Renaming in hsreplay 1.1
									amount: meta.data
									mainAction: mainAction
									sameOwnerAsParent: sameOwnerAsParent
									actionType: 'power-healing'
									data: @entities[command.attributes.entity]
									owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
									initialCommand: command
								}
								if mainAction
									mainAction.actions = mainAction.actions or []
									mainAction.actions.push action

								# If the preceding action is a "targeting" one, we remove it, as the info would be redundent
								if lastAction?.actionType is 'power-target'
									@turns[@currentTurnNumber].actions.pop()
									
								# console.log 'creating power-healing', action, meta
								@addAction @currentTurnNumber, action
			
			# Power overwhelming for instance doesn't use Meta tags
			else if parseInt(command.attributes.target) > 0
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
					actionType: 'played-card-with-target'
					data: @entities[command.attributes.entity]
					target: [command.attributes.target]
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
					for entity in fullEntities
						action = {
							turn: @currentTurnNumber - 1
							timestamp: tsToSeconds(entity.attributes.ts) || tsToSeconds(command.attributes.ts) || batch.timestamp
							index: entity.index
							actionType: 'trigger-fullentity'
							data: @entities[command.attributes.entity]
							owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
							newEntities: [entity]
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
				target: [command.attributes.target]
				initialCommand: command
			}
			@addAction @currentTurnNumber, action

			# TODO: log the damage done

	parseDeaths: (batch, command) ->
		if command.tags and command.attributes.type == '6' 
			for tag in command.tags
				# Graveyard
				if tag.tag == 'ZONE' and tag.value == 4
					# Ok, that's a death. Should we group them together?
					actions = @turns[@currentTurnNumber].actions
					if actions?.length > 0 and actions[actions.length - 1].actionType is 'minion-death'
						actions[actions.length - 1].deads.push tag.entity
					else
						action = {
							turn: @currentTurnNumber - 1
							timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp
							actionType: 'minion-death'
							data: tag.entity
							deads: [tag.entity]
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
				# console.log 'parsing discover action', command
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
				# console.log 'adding discover action', action
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
						index: entity.index
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
						index: entity.index
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


	parseFatigueDamage: (batch, command) ->
		if command.tag == 'FATIGUE'
			owner = @entities[command.entity]
			action = {
				turn: @currentTurnNumber
				timestamp: batch.timestamp
				actionType: 'fatigue-damage'
				data: [command.entity]
				damage: command.value
				mainAction: command.parent?.parent # It's a tag change, so we are interesting in the enclosing action
				owner: owner
				initialCommand: command
			}
			@addAction @currentTurnNumber, action

module.exports = ActionParser
