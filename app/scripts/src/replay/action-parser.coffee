Entity = require './entity'
Player = require './player'
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
		for item in @history
			## Populate relevant data for cards
			if item.command == 'receiveEntity'
				if item.node.id and !@entities[item.node.id]
					entity = new Entity(this)
					definition = _.cloneDeep item.node
					@entities[definition.id] = entity
					# Entity not in the game yet
					definition.tags.ZONE = 6
					entity.update(definition)
			# Order is important, since a card can be first created with fullentity then info (like card id) be added with 
			# showentity, eg rallying blade
			if item.command == 'receiveShowEntity'
				if item.node.id and @entities[item.node.id]
					@entities[item.node.id].cardID = item.node.cardID

		# Add intrinsic information, like whether the card is a secret
		for item in @history
			if item.command == 'receiveTagChange'
				# Adding information that this entity is a secret
				if item.node.tag == 'SECRET' and item.node.value == 1
					@entities[item.node.entity].tags[item.node.tag] = item.node.value
			if item.command == 'receiveShowEntity'
				if item.node.tags.SECRET == 1
					@entities[item.node.id].tags.SECRET = 1

		# Sometimes card type isn't precised
		for k,v of @entities
			card = @cardUtils.getCard(v.cardID)
			# console.log 'getting card', v.cardID, card
			if card?.type is 'Spell' and !v.tags.CARDTYPE
				v.tags.CARDTYPE = 5
			if card?.type is 'Enchantment' and !v.tags.CARDTYPE
				v.tags.CARDTYPE = 6


	parseActions: ->
		# Build the list of turns along with the history position of each
		@players = [@player, @opponent]
		@playerIndex = 0
		@turnNumber = 1
		@currentPlayer = @players[@playerIndex]

		for item in @history

			@parseMulliganTurn item
			@parseStartOfTurn item

			# The actual actions
			if item.command is 'receiveAction'
				@currentTurnNumber = @turnNumber - 1
				if (@turns[@currentTurnNumber])

					# We need to keep this one high priority, as it often has the same timestamp as its consequence
					@parseSecretRevealed item
					@parseMulliganCards item
					@parseCardPlayedFromHand item
					@parseHeroPowerUsed item
					@parseSecretPlayedFromHand item
					@parseAttacks item
					@parseDiscovers item
					@parsePowerEffects item
					@parseDeaths item
					@parseSummons item
					@parseEquipEffect item
					@parseTriggerFullEntityCreation item
					@parseTriggerPutSecretInPlay item
					@parseNewHeroPower item


			if item.command is 'receiveTagChange'
				@currentTurnNumber = @turnNumber - 1
				if (@turns[@currentTurnNumber])

					@parseFatigueDamage item

			# Keeping that for last in order to make some non-timestamped action more coherent (like losing life from life 
			# tap before drawing the card)
			@parseDrawCard item
			@parseOverdraw item
			@parseDiscardCard item

		# Sort the actions chronologically
		tempTurnNumber = 1
		while @turns[tempTurnNumber]
			# First remove actions that we don't want to consider, but that we didn't have enough information
			# to not log first (typically the power-target that targets self on a discover action)
			filterFunction = @filterAction
			filteredActions = _.filter @turns[tempTurnNumber].actions, filterFunction
			# console.log 'sorting actions for turn', tempTurnNumber
			sortedActions = _.sortBy filteredActions, 'index'
			# Post processing
			finalActions = @postProcess sortedActions

			@turns[tempTurnNumber].actions = finalActions
			# console.log '\tsorted', @turns[tempTurnNumber].actions
			tempTurnNumber++

	filterAction: (action) ->
		return true


	addAction: (currentTurnNumber, action) ->
		# Keep the initial game order
		action.index = action.index || action.initialCommand.index
		action.initialCommand.associatedAction = action
		@turns[currentTurnNumber].actions.push action


	# =======================
	# Post-processing
	# =======================
	postProcess: (actions) ->
		# http://stackoverflow.com/questions/9882284/looping-through-array-and-removing-items-without-breaking-for-loop
		for i in [actions.length - 1..1]
			# Can happen because we clean up
			if !actions[i]
				continue
			# Don't need to log both the targeting and the damage
			if actions[i].actionType is 'power-damage' and actions[i - 1].actionType is 'power-target'
				actions[i].index = actions[i - 1].index
				actions[i - 1] = undefined

		# Remove empty
		finalActions = _.compact actions

		return finalActions

	# =======================
	# Specific actions
	# =======================
	parseMulliganTurn: (item) ->
		# Mulligan
		# Add only one command for mulligan start, no need for both
		if item.command is 'receiveTagChange' and item.node.entity == 2 and item.node.tag == 'MULLIGAN_STATE' and item.node.value == 1
			@turns[@turnNumber] = {
				turn: 'Mulligan'
				playerMulligan: []
				opponentMulligan: []
				timestamp: item.timestamp
				actions: []
				index: item.index
			}
			@turns.length++
			@turnNumber++
			@currentPlayer = @players[++@playerIndex % 2]

		if item.command is 'receiveTagChange' and item.node.entity == 3 and item.node.tag == 'MULLIGAN_STATE' and item.node.value == 1
			@currentPlayer = @players[++@playerIndex % 2]	


	parseStartOfTurn: (item) ->
		# Start of turn
		if item.command is 'receiveTagChange' and item.node.entity == 1 and item.node.tag == 'STEP' and item.node.value == 6
			@turns[@turnNumber] = {
				# historyPosition: i
				turn: @turnNumber - 1
				timestamp: item.timestamp
				actions: []
				activePlayer: @currentPlayer
				index: item.index
			}
			@turns.length++
			@turnNumber++
			@currentPlayer = @players[++@playerIndex % 2]


	parseDrawCard: (item) ->
		currentCommand = item.node

		# Draw cards - 1 - Simply a card arriving in hand
		# But don't log cards that come back in hand from play
		if item.command is 'receiveTagChange' and currentCommand.tag == 'ZONE' and currentCommand.value == 3
			# Don't add card draws that are at the beginning of the game or during Mulligan
			if @currentTurnNumber >= 2
				while currentCommand.parent and currentCommand.entity not in ['2', '3']
					currentCommand = currentCommand.parent

				# When a card is played that makes you draw, the "root" action isn't an action owned by the player, 
				# but by the card itself. So we need to find out who that card controller is
				# ownerId = currentCommand.attributes.entity
				ownerId = item.node.entity
				if ownerId not in ['2', '3']
					owner = @getController(@entities[ownerId].tags.CONTROLLER)
				else
					owner = @entities[ownerId]

				lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
				if lastAction?.actionType is 'card-draw' and lastAction.owner.id is owner.id
					lastAction.data.push item.node.entity
				else
					action = {
						turn: @currentTurnNumber
						timestamp: item.timestamp
						actionType: 'card-draw'
						type: 'from tag change'
						# old data attributes, could be removed now that we do a full process beforehand
						data: [item.node.entity]
						fullData: @entities[item.node.entity]
						mainAction: item.node.parent?.parent # It's a tag change, so we are interesting in the enclosing action
						owner: owner
						initialCommand: item.node
						debug_lastAction: lastAction
						debug_entity: @entities[item.node.entity]
						shouldExecute: =>
							# console.log action.fullData, action.fullData.lastZone, action.fullData.tags.ZONE
							return action.fullData.tags.ZONE != 1
					}
					@addAction @currentTurnNumber, action

		# Draw cards - 2 - The player draws a card, thus revealing a full entity
		if item.command is 'receiveAction'
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

				entities = item.node.showEntities || item.node.fullEntities
				if entities
					currentCommand = item.node
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
									timestamp: item.timestamp
									actionType: 'card-draw'
									type: 'from action'
									data: [entity.id]
									mainAction: item.node.parent
									owner: owner
									initialCommand: item.node
									debug_lastAction: lastAction
								}
								@addAction @currentTurnNumber, action

	parseDiscardCard: (item) ->
		currentCommand = item.node

		# Draw cards - 1 - Simply a card arriving in hand
		# But don't log cards that come back in hand from play
		if item.command is 'receiveTagChange' and currentCommand.tag == 'ZONE' and currentCommand.value == 4
			# Don't add card discards that are at the beginning of the game or during Mulligan
			if @currentTurnNumber >= 2
				while currentCommand.parent and currentCommand.entity not in ['2', '3']
					currentCommand = currentCommand.parent

				# When a card is played that makes you draw, the "root" action isn't an action owned by the player, 
				# but by the card itself. So we need to find out who that card controller is
				# ownerId = currentCommand.attributes.entity
				ownerId = item.node.entity
				if ownerId not in ['2', '3']
					owner = @getController(@entities[ownerId].tags.CONTROLLER)
				else
					owner = @entities[ownerId]

				lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
				if lastAction?.actionType is 'card-discard' and lastAction.owner.id is owner.id
					lastAction.data.push item.node.entity
				else
					action = {
						turn: @currentTurnNumber
						timestamp: item.timestamp
						actionType: 'card-discard'
						type: 'from tag change'
						# old data attributes, could be removed now that we do a full process beforehand
						data: [item.node.entity]
						fullData: @entities[item.node.entity]
						mainAction: item.node.parent?.parent # It's a tag change, so we are interesting in the enclosing action
						owner: owner
						initialCommand: item.node
						debug_lastAction: lastAction
						debug_entity: @entities[item.node.entity]
						shouldExecute: =>
							return action.fullData.tags.ZONE == 3
					}
					@addAction @currentTurnNumber, action

	parseOverdraw: (item) ->
		currentCommand = item.node

		# Draw cards - 2 - The player draws a card, thus revealing a full entity
		if item.command is 'receiveAction'
			while currentCommand.parent and currentCommand.entity not in ['2', '3']
				currentCommand = currentCommand.parent

			# When a card is played that makes you draw, the "root" action isn't an action owned by the player, 
			# but by the card itself. So we need to find out who that card controller is
			ownerId = currentCommand.attributes.entity
			if ownerId not in ['2', '3']
				owner = @getController(@entities[ownerId].tags.CONTROLLER)
			else
				owner = @entities[ownerId]

			entities = item.node.showEntities || item.node.fullEntities
			if entities
				currentCommand = item.node
				while currentCommand.parent and currentCommand.entity not in ['2', '3']
					currentCommand = currentCommand.parent
				
				for entity in entities
					# ShowEntities are revealed with a zone = GRAVEYARD
					if entity.tags.ZONE == 4
						lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
						if lastAction?.actionType is 'overdraw' and lastAction.owner.id is parseInt(owner.id)
							lastAction.data.push entity.id
						else
							action = {
								turn: @currentTurnNumber
								timestamp: item.timestamp
								actionType: 'overdraw'
								data: [entity.id]
								mainAction: item.node.parent
								owner: owner
								initialCommand: item.node
								debug_lastAction: lastAction
							}
							@addAction @currentTurnNumber, action

	parseMulliganCards: (item) ->
		command = item.node
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
	parseCardPlayedFromHand: (item) ->
		command = item.node
		if command.attributes.type == '7'

			# Check that the entity was in our hand before
			entity = @entities[command.attributes.entity]

			playedCard = -1
			# The case of a ShowEntity command when the card was already known - basically 
			# when we play our own card. In that case, the tags are already known, and 
			# tag changes are the only things we care about
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value in [1]
					# Check that we are not revealing an enchantmnent
					if @entities[tag.entity].tags.CARDTYPE != 6
						playedCard = tag.entity

			# The case of a ShowEntity (or FullEntity) when we didn't previously know the 
			# card. In that case, a ShowEntity (or FullEntity) element is created that contains
			# the tag with the proper zone
			# Use entities when playing Eviscerate at t6o at http://www.zerotoheroes.com/r/hearthstone/572de12ee4b0d4231295c49e/an-arena-game-going-5-0
			if playedCard < 0 and command.showEntities
				for showEntity in command.showEntities
					if showEntity.tags.ZONE in [1] and showEntity.tags.CARDTYPE != 6
						playedCard = showEntity.id

			# Possibly check that the card was in hand before being in play?
			if playedCard > -1
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'played-card-from-hand'
					data: @entities[playedCard]
					owner: @turns[@currentTurnNumber].activePlayer
					initialCommand: command
				}
				# console.log '\tAnd it is a valid play', action
				@addAction @currentTurnNumber, action

	parseNewHeroPower: (item) ->
		command = item.node
		if command.attributes.type in ['3', '5'] and command.tags
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value == 1
					entity = @entities[tag.entity]
					card = @replay.cardUtils.getCard(entity['cardID'])
					if card.type == 'Hero Power'
						action = {
							turn: @currentTurnNumber - 1
							timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
							actionType: 'new-hero-power'
							data: entity
							owner: @getController(entity.tags.CONTROLLER)
							initialCommand: command
						}
						# console.log 'receving a new hero power', action
						# console.log '\tAnd it is a valid play', action
						@addAction @currentTurnNumber, action

	parseHeroPowerUsed: (item) ->
		command = item.node
		if command.attributes.type == '7'

			# Check that the entity was in our hand before
			entity = @entities[command.attributes.entity]
			# console.log 'Considering play of', entity, command

			if entity.tags.CARDTYPE == 10
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'hero-power'
					data: entity
					owner: @getController(entity.tags.CONTROLLER)
					initialCommand: command
				}
				# console.log '\tAnd it is a valid play', action
				@addAction @currentTurnNumber, action

	parseSecretPlayedFromHand: (item) ->
		command = item.node
		if command.attributes.type == '7'

			playedCard = -1
			secret = false
			for tag in command.tags
				# Either in play or a secret
				if tag.tag == 'ZONE' and tag.value == 7
					playedCard = tag.entity
					# console.log 'is secret played action?', @entities[playedCard].cardID, command, @entities[playedCard]
				if tag.tag == 'SECRET' and tag.value == 1
					secret = true

			if !secret and @entities[playedCard]?.tags.SECRET == 1
				secret = true

			if playedCard > -1 and secret
				entity = @entities[playedCard]
				owner = @getController(entity.tags.CONTROLLER) 
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'played-secret-from-hand'
					# If it's a secret, we want to know who put it in play
					data: entity
					owner: owner
					initialCommand: command
				}
				@addAction @currentTurnNumber, action



	# Damage, healing and jousts
	parsePowerEffects: (item) ->
		command = item.node
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
							# Prezvent a spell from targeting itself
							if parseInt(command.attributes.entity) == info.entity and @entities[command.attributes.entity].tags.CARDTYPE == 5
								continue

							if mainAction?.actions 
								for action in mainAction.actions
									# If the same source deals the same amount of damage, we group all of that together
									if action.actionType is 'power-target' and action.data.id is parseInt(command.attributes.entity)
										action.target.push info.entity
										action.index = meta.index
										subAction = true

							# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
							lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
							if !mainAction and lastAction?.actionType is 'power-target' and lastAction.data.id is parseInt(command.attributes.entity)
								# console.log 'previous action is target, dont add this one', lastAction, command, lastAction.actionType, lastAction.actionType is 'power-target'
								lastAction.target.push info.entity
								lastAction.index = meta.index
								subAction = true

							# subAction = false
							if !subAction and !(lastAction?.actionType is 'discover')
								action = {
									turn: @currentTurnNumber - 1
									timestamp: meta.ts || tsToSeconds(command.attributes.ts) || item.timestamp
									index: meta.index
									target: [info.entity]
									mainAction: mainAction
									sameOwnerAsParent: sameOwnerAsParent
									actionType: 'power-target'
									data: @entities[command.attributes.entity]
									owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
									initialCommand: command
									previousAction: lastAction
									debug_target: @entities[info.entity]
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
										action.index = meta.index
										subAction = true

							# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
							lastActionIndex = 1
							initialLastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - lastActionIndex]
							if !mainAction 

								lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - lastActionIndex]
								while lastAction?.actionType is 'power-damage'
									lastActionIndex++
									# Make sure it's the same entity at the root of both action
									if lastAction.data.id != parseInt(command.attributes.entity)
										lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - lastActionIndex]
										continue

									if lastAction.amount is meta.data
										lastAction.target.push info.entity
										lastAction.index = meta.index
										subAction = true
										break

									if @turns[@currentTurnNumber].actions.length - lastActionIndex < 0
										break

									lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - lastActionIndex]
										
							if !subAction
								action = {
									turn: @currentTurnNumber - 1
									timestamp: meta.ts || tsToSeconds(command.attributes.ts) || item.timestamp
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
									debug_initialLastAction: initialLastAction
								}
								if mainAction
									mainAction.actions = mainAction.actions or []
									mainAction.actions.push action

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
									timestamp: meta.ts || tsToSeconds(command.attributes.ts) || item.timestamp
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
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'played-card-with-target'
					data: @entities[command.attributes.entity]
					target: [command.attributes.target]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					initialCommand: command
				}
				@addAction @currentTurnNumber, action

	parseTriggerPutSecretInPlay: (item) ->
		command = item.node
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
						timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
						secrets: secretsPutInPlay
						mainAction: command.parent
						actionType: 'trigger-secret-play'
						data: @entities[command.attributes.entity]
						owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
						initialCommand: command
					}
					@addAction @currentTurnNumber, action

	# The other effects, like battlecry, echoing ooze duplication, etc.
	parseTriggerFullEntityCreation: (item) ->
		command = item.node
		if command.attributes.type in ['5'] 
			
			if command.fullEntities?.length > 0
				entities = command.fullEntities

			else if command.showEntities?.length > 0
				entities = command.showEntities

			# Trigger that creates an entity
			if entities?.length > 0
				fullEntities = _.filter(entities, (entity) -> entity.tags.ZONE == 1 )
				if fullEntities?.length > 0
					for entity in fullEntities
						action = {
							turn: @currentTurnNumber - 1
							timestamp: tsToSeconds(entity.attributes.ts) || tsToSeconds(command.attributes.ts) || item.timestamp
							index: entity.index
							actionType: 'trigger-fullentity'
							data: @entities[command.attributes.entity]
							owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
							newEntities: [entity]
							initialCommand: command
						}
						@addAction @currentTurnNumber, action


	parseAttacks: (item) ->
		command = item.node
		if command.attributes.type == '1'
			#console.log 'considering attack', command
			action = {
				turn: @currentTurnNumber - 1
				timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
				actionType: 'attack'
				data: @entities[command.attributes.entity]
				owner: @turns[@currentTurnNumber].activePlayer
				target: [command.attributes.target]
				initialCommand: command
			}
			@addAction @currentTurnNumber, action

			# TODO: log the damage done

	parseDeaths: (item) ->
		command = item.node
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
							timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
							actionType: 'minion-death'
							data: tag.entity
							deads: [tag.entity]
							initialCommand: command
						}
						@addAction @currentTurnNumber, action


	parseDiscovers: (item) ->
		command = item.node
		# Always discover 3 cards
		# A Light in the Darkness breaks this, as it creates another entity for the enchantment
		if command.attributes.type == '3' and command.fullEntities?.length >= 3
			# Check that each of them is in the SETASIDE zone
			isDiscover = true
			choices = []
			# console.log 'discovering?', command
			for entity in command.fullEntities
				# console.log '\tdiscovering?', entity, @entities[entity.id]
				# Have to do this for ALitD - no Enchantments
				if @entities[entity.id].tags.CARDTYPE != 6
					choices.push entity
					if entity.tags.ZONE != 6
						isDiscover = false

			if isDiscover and choices.length == 3
				# console.log 'parsing discover action', command, choices
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'discover'
					data: @entities[command.attributes.entity]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					choices: choices
					initialCommand: command
				}
				command.isDiscover = true
				# console.log 'adding discover action', action
				@addAction @currentTurnNumber, action


	parseSummons: (item) ->
		command = item.node
		# A power that creates new entities - minions
		if command.attributes.type in ['3'] 

			if command.fullEntities?.length > 0
				entities = command.fullEntities

			else if command.showEntities?.length > 0
				entities = command.showEntities

			if entities
				for entity in entities
					# Only care about summons here, which are entities that come in play directly
					# And summons only concerns minions - specific handlers take care of the rest
					if entity.tags.ZONE == 1 and entity.tags.CARDTYPE == 4
						# Is the effect triggered in response to another play?
						if command.parent
							mainAction = command.parent

						action = {
							turn: @currentTurnNumber - 1
							timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
							index: entity.index
							actionType: 'summon-minion'
							data: entity
							owner: @getController(entity.tags.CONTROLLER)
							mainAction: mainAction
							initialCommand: command
						}
						@addAction @currentTurnNumber, action

	parseEquipEffect: (item) ->
		command = item.node
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
						timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
						index: entity.index
						actionType: 'summon-weapon'
						data: entity
						owner: @getController(entity.tags.CONTROLLER)
						mainAction: mainAction
						initialCommand: command
					}
					@addAction @currentTurnNumber, action

	parseSecretRevealed: (item) ->
		command = item.node
		if command.attributes.type == '5'
			entity = @entities[command.attributes.entity]
			if entity?.tags?.SECRET == 1
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'secret-revealed'
					data: entity
					initialCommand: command
				}
				@addAction @currentTurnNumber, action


	parseFatigueDamage: (item) ->
		command = item.node
		if command.tag == 'FATIGUE'
			owner = @entities[command.entity]
			action = {
				turn: @currentTurnNumber
				timestamp: item.timestamp
				actionType: 'fatigue-damage'
				data: [command.entity]
				damage: command.value
				mainAction: command.parent?.parent # It's a tag change, so we are interesting in the enclosing action
				owner: owner
				initialCommand: command
			}
			@addAction @currentTurnNumber, action

module.exports = ActionParser
