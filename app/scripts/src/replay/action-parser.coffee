Entity = require './entity'
Player = require './player'
_ = require 'lodash'
moment = require 'moment'
EventEmitter = require 'events'

tsToSeconds = (ts) ->
	return moment(ts, [moment.ISO_8601, 'HH:mm:ss']).unix()

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

		@turnNumber = 1


	populateEntities: ->
		players = [@player, @opponent]
		@player.tags.RESOURCES_USED = 0
		@opponent.tags.RESOURCES_USED = 0

		#First add the missing card / entity info
		playerIndex = 0
		actionIndex = 0
		currentPlayer = players[playerIndex]

		# populate the entities
		for item in @history
			# console.log 'item', item
			if item.command == 'receiveGameEntity'
				# console.log 'game', item.node, item
				@replay.turnOffset = item.node.tags['TURN'] - 1 || 0
				# console.log 'starting game at turn', @turnNumber
			else if item.command == 'receivePlayer'
				if item.node.tags['CURRENT_PLAYER'] is 1
					# console.log 'CURRENT_PLAYER tag present', item, @player, @opponent
					if @player.id is item.node.id
						@currentPlayer = @player
					else if @opponent.id is item.node.id
						@currentPlayer = @opponent
					else
						console.error 'could not set current player'
					# Need to create a fake first turn
					# We create it twice to not mess with the logic that assumes that first turn
					# is mulligan with no active player
					@createFirstTurnForSpectate item
					@createFirstTurnForSpectate item

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
				# Adding information that this entity is a quest
				if item.node.tag == 'QUEST' and item.node.value == 1
					@entities[item.node.entity].tags[item.node.tag] = item.node.value
				# Add parent tag, needed for discover
				if item.node.tag == 'PARENT_CARD'
					@entities[item.node.entity].tags[item.node.tag] = item.node.value
				# Since patch 5.2.0.13619, the CURRENT_PLAYER is sent afterwards as a tag change
			if item.command == 'receiveShowEntity'
				if item.node.tags.SECRET == 1
					@entities[item.node.id].tags.SECRET = 1
			if item.command == 'receiveChoices'
				@usesChoices = true
				console.log 'using choices'

		# Sometimes card type isn't precised
		for k,v of @entities
			card = @cardUtils.getCard(v.cardID)
			# console.log 'getting card', v.cardID, card
			if card?.type is 'Spell' and !v.tags.CARDTYPE
				v.tags.CARDTYPE = 5
			if card?.type is 'Enchantment' and !v.tags.CARDTYPE
				v.tags.CARDTYPE = 6
			# Init 0 damage to make rollbacking easier
			if card?.type is 'Minion'
				v.tags.DAMAGE = 0


	parseActions: ->
		# Build the list of turns along with the history position of each
		@players = [@player, @opponent]

		@playerIndex = 0
		# @currentPlayer = @players[@playerIndex]
		# console.log 'parsing history', @history

		for item in @history

			# console.log 'parsing history item', item

			@parseMulliganTurn item
			@parseChangeActivePlayer item
			@parseStartOfTurn item

			# The actual actions
			if item.command is 'receiveAction'
				@currentTurnNumber = @turnNumber - 1
				if (@turns[@currentTurnNumber])

					# We need to keep this one high priority, as it often has the same timestamp as its consequence
					@parseSecretRevealed item
					@parseQuestCompleted item
					@parseMulliganCards item
					@parseCardPlayedFromHand item
					@parseHeroPowerUsed item
					@parseSecretPlayedFromHand item
					@parseQuestPlayedFromHand item
					@parseAttacks item
					@parseDiscoversOld item
					@parsePowerEffects item
					@parseDeaths item
					@parseSummons item
					@parseEquipEffect item
					@parseTriggerFullEntityCreation item
					@parseTriggerPutSecretInPlay item
					@parseNewHeroPower item
				else
					# console.log 'no turn number', @currentTurnNumber, @turns[@currentTurnNumber], @turns, @turns.length, item

			if item.command is 'receiveTagChange'
				@currentTurnNumber = @turnNumber - 1
				if @turns[@currentTurnNumber]
					@parseFatigueDamage item
					@parseEndGame item
					@parseMinionCasting item

			if item.command is 'receiveChoices'
				@parseDiscovers item

			if item.command is 'receiveChosenEntities'
				@parseDiscoverPick item

			if item.command is 'receiveEntity'
				@parseCardPlayedByMinion item

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
			# console.log 'sorted actions', sortedActions
			# Post processing
			finalActions = @postProcess sortedActions
			# console.log 'final actions', finalActions

			@turns[tempTurnNumber].actions = finalActions
			# console.log '\tsorted', @turns[tempTurnNumber].actions
			tempTurnNumber++

	filterAction: (action) ->
		return true


	addAction: (currentTurnNumber, action) ->
		# Keep the initial game order
		action.index = action.index || action.initialCommand.index
		action.rollbackInfo = {}
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
			if actions[i].actionType is 'power-damage' and actions[i - 1]?.actionType is 'power-target'
				actions[i].index = actions[i - 1].index
				actions[i - 1] = undefined

			# Until we support the Choices elements properly
			if !@usesChoices and actions[i].actionType is 'discover' and actions[i + 1]?.actionType is 'card-draw'
				actions[i].discovered = actions[i + 1].data[0]

			if !actions[i].owner
				# console.log 'adding owner', actions[i], @turns[actions[i].turn], @turns
				# Because turn 1 is Mulligan
				actions[i].owner = @turns[actions[i].turn + 1]?.activePlayer

		# Remove empty
		finalActions = _.compact actions

		return finalActions

	# =======================
	# Specific actions
	# =======================
	parseMulliganTurn: (item) ->
		# Mulligan
		# Add only one command for mulligan start, no need for both
		if item.command is 'receiveTagChange' and item.node.entity in [2, 3] and item.node.tag == 'MULLIGAN_STATE' and item.node.value == 1
			# console.log 'parsing mulligan', item
			if @turns[1]
				@turns[1].index = Math.max @turns[1].index, item.index
			else
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

	parseChangeActivePlayer: (item) ->
		if item.command is 'receiveTagChange' and item.node.entity in [2, 3] and item.node.tag == 'CURRENT_PLAYER' and item.node.value == 1 and @currentTurnNumber >= 2
				previousPlayer = @currentPlayer
				@currentPlayer = _.find @players, (o) ->
					return o.id == item.node.entity

				# if @turns[@turnNumber - 1] and !@turns[@turnNumber - 1]?.activePlayer
				# 	console.log 'no active player, forcing it', @turns[@turnNumber - 1]

				# Looks like the first turn doesn't get the tag, so we deduce the active player was the one who didn't
				# become active player next turn
				if !previousPlayer and @turns[@turnNumber - 1] and !@turns[@turnNumber - 1]?.activePlayer
					@turns[@turnNumber - 1].activePlayer = _.find @players, (o) ->
						return o.id != item.node.entity

					# console.log 'setting back active player', item, @turns[@turnNumber - 1].activePlayer

				# console.log 'switching active player', item, @currentPlayer, @players

	parseStartOfTurn: (item) ->
		# Start of turn
		if item.command is 'receiveTagChange' and item.node.entity == 1 and item.node.tag == 'STEP' and item.node.value == 6
			# console.log 'parsing start of turn', item, @currentPlayer
			@turns[@turnNumber] = {
				# historyPosition: i
				turn: @turnNumber - 1
				timestamp: item.timestamp
				actions: []
				activePlayer: @currentPlayer
				index: item.index
			}
			# console.log 'parsing start of turn', item, @turns[@turnNumber], @turns
			@turns.length++
			@turnNumber++
			# @currentPlayer = @players[++@playerIndex % 2]


	createFirstTurnForSpectate: (item) ->
		console.log 'creating fake turn', @turnNumber, @turns
		@turns[@turnNumber] = {
			turn: @turnNumber - 1
			timestamp: item.timestamp
			actions: []
			activePlayer: @currentPlayer
			index: undefined
		}
		@turns.length++
		@turnNumber++

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
							# return true
							action.executed = action.executed || action.fullData.tags.ZONE != 1
							# console.log 'should execute', action
							# console.log 'shouldexecute?', action.fullData, action.fullData.lastZone, action.fullData.tags.ZONE, action
							# https://github.com/Zero-to-Heroes/zerotoheroes.com/issues/50
							return action.executed
							# Leads to complex scenarios, and we'd probably need to rething the whole engine from the ground up
							# to take all of this into account
							# return action.fullData.tags.ZONE != 1
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
							# return true
							action.executed = action.executed || action.fullData.tags.ZONE == 3
							# console.log 'should execute', action
							return action.executed
							# console.log 'should execute discard?', action.fullData, action.fullData.tags.ZONE
							#  https://github.com/Zero-to-Heroes/manastorm/issues/44
							# return true
							# https://github.com/Zero-to-Heroes/manastorm/issues/53
							# return action.fullData.tags.ZONE == 3
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
		# Prince Malchezaar has the same signature, but with a different entity ID
		if command.attributes.type == '5' and @currentTurnNumber == 1 and command.hideEntities and command.attributes.entity in ['2', '3']
			# console.log 'parsing mulligan cards hideEntities', command
			@turns[@currentTurnNumber].playerMulligan = command.hideEntities

		# Mulligan opponent
		if command.attributes.type == '5' and @currentTurnNumber == 1 and command.attributes.entity != @mainPlayerId and command.tags
			mulliganed = []
			# console.log 'debug opponent mulligan', command, command.tags
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value == 2
					@turns[@currentTurnNumber].opponentMulligan.push tag.entity


	# Not secrets
	parseCardPlayedFromHand: (item) ->
		command = item.node
		playedCard = -1

		# Standard spell casting
		if command.attributes.type == '7' and command.tags
			# Check that the entity was in our hand before
			entity = @entities[command.attributes.entity]

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



		if playedCard > -1
			# target = if command.attributes.target is '0' then null else command.attributes.target
			action = {
				turn: @currentTurnNumber - 1
				timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
				actionType: 'played-card-from-hand'
				data: @entities[playedCard]
				# target: [command.attributes.target]
				owner: @turns[@currentTurnNumber].activePlayer
				initialCommand: command
			}

			# console.log '\tAnd it is a valid play', action
			@addAction @currentTurnNumber, action


	parseCardPlayedByMinion: (item) ->
		command = item.node
		playedCard = -1

		# Spell cast by a minion (typically Yogg or Servant of Yogg)
		if @minionCasting and command.tags.CREATOR is @minionCasting
			action = {
				turn: @currentTurnNumber - 1
				timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
				actionType: 'played-card-by-minion'
				data: @entities[command.id]
				# target: [command.attributes.target]
				owner: @turns[@currentTurnNumber].activePlayer
				initialCommand: command
			}
			console.log 'minion casting', action
			@addAction @currentTurnNumber, action



	parseNewHeroPower: (item) ->
		command = item.node
		if command.attributes.type in ['3', '5'] and command.tags
			for tag in command.tags
				if tag.tag == 'ZONE' and tag.value == 1
					entity = @entities[tag.entity]
					card = @replay.cardUtils.getCard(entity['cardID'])
					# console.log 'getting card', card, entity['cardID'], entity
					if card?.type == 'Hero Power'
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
		if command.attributes.type == '7' and command.tags

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
				console.log 'secret played from hand', action
				@addAction @currentTurnNumber, action



	parseQuestPlayedFromHand: (item) ->
		command = item.node
		if command.attributes.type == '7'

			# main player
			if command.tags
				playedCard = -1
				quest = false
				for tag in command.tags
					# Either in play or a quest
					if tag.tag == 'ZONE' and tag.value == 7
						playedCard = tag.entity
					if tag.tag == 'QUEST' and tag.value == 1
						quest = true

				if !quest and @entities[playedCard]?.tags.QUEST == 1
					quest = true

				if playedCard > -1 and quest
					entity = @entities[playedCard]
					owner = @getController(entity.tags.CONTROLLER)
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
						actionType: 'played-quest-from-hand'
						# If it's a secret, we want to know who put it in play
						data: entity
						owner: owner
						initialCommand: command
					}
					@addAction @currentTurnNumber, action

			# opponent
			if !action and command.showEntity and command.showEntity.tags
				playedCard = -1
				quest = false
				# Either in play or a quest
				if command.showEntity.tags.ZONE == 7 and command.showEntity.tags.QUEST == 1
					playedCard = parseInt(command.attributes.entity)
					quest = true

				if !quest and @entities[playedCard]?.tags.QUEST == 1
					quest = true

				if playedCard > -1 and quest
					entity = @entities[playedCard]
					owner = @getController(entity.tags.CONTROLLER)
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
						actionType: 'played-quest-from-hand'
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

			# Hard-code for Malchezaar
			if @entities[command.attributes.entity]?.cardID is 'KAR_096' and command.attributes.type is '5'
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'splash-reveal'
					data: @entities[command.attributes.entity]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					initialCommand: command
				}
				@addAction @currentTurnNumber, action

			# console.log 'consider power effects', command.attributes.entity

			else if command.meta?.length > 0
				for meta in command.meta
					if !meta.info and !meta.meta
						continue

					# The HSReplay version
					if !meta.info and meta.meta
						@addMeta item, meta, meta

					if meta.info
						for info in meta.info
							@addMeta item, meta, info



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

	# TODO: all cases are really similar, probably possible to regroup all of them?
	addMeta: (item, meta, info) ->

		command = item.node
		# If the entity that triggers the power is something that just did an action, we don't log that again
		sameOwnerAsParent = (command.parent?.attributes?.entity == command.attributes.entity)

		# Is the effect triggered in response to another play?
		if command.parent
			mainAction = command.parent

		subAction = false
		target = info.entity
		if !target and command.attributes.target isnt '0'
			target = command.attributes.target

		if !target
			return

		# The power simply targets something else
		if meta.meta == 'TARGET'

			# Prezvent a spell from targeting itself
			if parseInt(command.attributes.entity) == info.entity and @entities[command.attributes.entity].tags.CARDTYPE == 5
				return

			if mainAction?.actions
				for action in mainAction.actions

					# If the same source deals the same amount of damage, we group all of that together
					if action.actionType is 'power-target' and action.data.id is parseInt(command.attributes.entity)
						# If no info node (hsreplay), then default to action target
						action.target.push target
						action.target = _.uniq action.target
						action.index = meta.index
						subAction = true

			# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
			lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
			if !mainAction and lastAction?.actionType is 'power-target' and lastAction.data.id is parseInt(command.attributes.entity)
				# console.log 'previous action is target, dont add this one', lastAction, command, lastAction.actionType, lastAction.actionType is 'power-target'
				lastAction.target.push target
				lastAction.target = _.uniq lastAction.target
				lastAction.index = meta.index
				subAction = true

			# subAction = false
			if !subAction and !(lastAction?.actionType is 'discover')
				action = {
					turn: @currentTurnNumber - 1
					timestamp: meta.ts || tsToSeconds(command.attributes.ts) || item.timestamp
					index: meta.index
					target: [target]
					mainAction: mainAction
					sameOwnerAsParent: sameOwnerAsParent
					actionType: 'power-target'
					data: @entities[command.attributes.entity]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					initialCommand: command
					previousAction: lastAction
					# Some cards have an effect on cards in hand, and we don't know this when building the actions list
					# Used by the turnlog to decide what to display
					revealTarget: (replay) =>
						# Always show effects on ourself
						shouldHide = action.owner is replay.opponent
						# console.log '\tshouldHide1?', shouldHide, action.owner, replay.opponent
						# Only hide effects that happen on the cards in hand
						shouldHide = shouldHide && @entities[action.target[0]]?.tags?.ZONE is 3
						# console.log '\tshouldHide2?', shouldHide, @entities[action.target[0]]?.tags?.ZONE, action.target[0], @entities[action.target[0]]
						# Don't hide the effects if we're showing all the cards
						shouldHide = shouldHide && !replay.showAllCards
						# console.log '\tshouldHide3?', shouldHide, replay.showAllCards
						if shouldHide
							return false
						return true
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
					if action.actionType is 'power-damage' and action.data.id is parseInt(command.attributes.entity)
						action.target.push target
						action.target = _.uniq action.target
						action.index = meta.index
						subAction = true

						if action.targets[target]
							action.targets[target] = action.targets[target] + parseInt(meta.data)
						else
							action.targets[target] = parseInt(meta.data)



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

					# if lastAction.amount is meta.data
					lastAction.target.push target
					lastAction.target = _.uniq lastAction.target
					lastAction.index = meta.index
					subAction = true

					if !lastAction.targets
						lastAction.targets = {}

					if lastAction.targets[target]
						lastAction.targets[target] = lastAction.targets[target] + parseInt(meta.data)
					else
						lastAction.targets[target] = parseInt(meta.data)
					# break

					if @turns[@currentTurnNumber].actions.length - lastActionIndex < 0
						break

					lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - lastActionIndex]

			if !subAction
				action = {
					turn: @currentTurnNumber - 1
					timestamp: meta.ts || tsToSeconds(command.attributes.ts) || item.timestamp
					index: meta.index
					target: [target]
					targets: {}
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
				action.targets[target] = parseInt(meta.data)
				if mainAction
					mainAction.actions = mainAction.actions or []
					mainAction.actions.push action

				@addAction @currentTurnNumber, action

		# The power healed someone
		if meta.meta == 'HEALING'
			if mainAction?.actions
				for action in mainAction.actions
					# If the same source deals the same amount of damage, we group all of that together
					if action.actionType is 'power-healing' and action.data.id is parseInt(command.attributes.entity)
						action.target.push target
						action.target = _.uniq action.target
						action.index = meta.index
						subAction = true

						if action.targets[target]
							action.targets[target] = action.targets[target] + parseInt(meta.data)
						else
							action.targets[target] = parseInt(meta.data)

			# Check if previous action is not the same as the current one (eg Healing Totem power is not a sub action)
			lastAction = @turns[@currentTurnNumber].actions[@turns[@currentTurnNumber].actions.length - 1]
			if !mainAction and lastAction?.actionType is 'power-healing' and lastAction.data.id is parseInt(command.attributes.entity)
				lastAction.target.push target
				lastAction.target = _.uniq lastAction.target
				lastAction.index = meta.index
				subAction = true

				if !lastAction.targets
					lastAction.targets = {}

				if lastAction.targets[target]
					lastAction.targets[target] = lastAction.targets[target] + parseInt(meta.data)
				else
					lastAction.targets[target] = parseInt(meta.data)

			if !subAction
				action = {
					turn: @currentTurnNumber - 1
					timestamp: meta.ts || tsToSeconds(command.attributes.ts) || item.timestamp
					index: meta.index
					target: [target]
					targets: {}
					# Renaming in hsreplay 1.1
					amount: meta.data
					mainAction: mainAction
					sameOwnerAsParent: sameOwnerAsParent
					actionType: 'power-healing'
					data: @entities[command.attributes.entity]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					initialCommand: command
				}
				action.targets[target] = parseInt(meta.data)
				if mainAction
					mainAction.actions = mainAction.actions or []
					mainAction.actions.push action

				# If the preceding action is a "targeting" one, we remove it, as the info would be redundent
				if lastAction?.actionType is 'power-target'
					@turns[@currentTurnNumber].actions.pop()

				# console.log 'creating power-healing', action, meta
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
						index = tag.index

				if secretsPutInPlay.length > 0
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
						index: index
						secrets: secretsPutInPlay
						mainAction: command.parent
						actionType: 'trigger-secret-play'
						data: @entities[command.attributes.entity]
						owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
						initialCommand: command
					}
					console.log 'secret put in play', action
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
			# console.log 'considering attack', command, entity, command.target, command
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

		if command.type is '2'
			console.log 'possible choices', command

			choices = []
			for entity in command.cards
				console.log '\tdiscovering?', entity, @entities[entity]
				choices.push @entities[entity]

			action = {
				turn: @currentTurnNumber - 1
				timestamp: tsToSeconds(command.ts) || item.timestamp
				actionType: 'discover'
				data: @entities[command.source]
				owner: @entities[command.entity]
				choices: choices
				initialCommand: command
			}
			command.isDiscover = true
			@addAction @currentTurnNumber, action
			console.log 'added discover action', action, @turns[@currentTurnNumber], @turns
			# console.log 'parsing discover action', action, command, choices, actionChoices, @entities[command.attributes.entity], numberOfChoices


	parseDiscoverPick: (item) ->
		command = item.node
		console.log 'considering last pick', item, @turns[@currentTurnNumber].actions, @currentTurnNumber, @turns

		lastAction = @turns[@currentTurnNumber].actions?[@turns[@currentTurnNumber].actions.length - 1];
		if lastAction?.actionType is 'discover'
			lastAction.discovered = @entities[command.cards[0]]?.id
			console.log 'highlighting pick', lastAction, item


	parseDiscoversOld: (item) ->
		if @usesChoices
			return

		command = item.node

		numberOfChoices = 3

		# Hard-code Yogg-Saron. There might be a way to get around this using "Choices" block instead (Yogg doesn't have them)
		# This will have to be for a later phase, as it's way more work (though cleaner)
		if @entities[command.attributes.entity]?.cardID == 'OG_134'
			return

		# Also hard-code Evolve and Devolve
		if @entities[command.attributes.entity]?.cardID in ['OG_027', 'CFM_696']
			return

		# Kalimos
		if @entities[command.attributes.entity]?.cardID == 'UNG_211'
			# console.log 'discovering from Kalimos'
			numberOfChoices = 4

		# Always discover 3 cards
		# A Light in the Darkness breaks this, as it creates another entity for the enchantment
		# Vicious Fledgling discovers after an attack, so it's a result of a power, not a card played
		if command.attributes.type in ['3', '5'] and command.fullEntities?.length >= numberOfChoices
			entities = command.fullEntities
			# Tracking discovers from our own deck, so it doesn't actually create cards
			fullEntities = true
		else if command.attributes.type in ['3', '5'] and command.showEntities?.length >= numberOfChoices
			entities = command.showEntities


		if entities

			isDiscover = true
			choices = []

			# console.log 'discovering?', @entities[command.attributes.entity].cardID, command
			for entity in entities
				# console.log '\tdiscovering?', entity, @entities[entity.id]
				# Have to do this for ALitD - no Enchantments
				# PARENT_CARD is for the "choose one" variations
				# Check that each of them is in the SETASIDE zone
				if @entities[entity.id].tags.CARDTYPE != 6 && !@entities[entity.id].tags.PARENT_CARD && (!fullEntities || @entities[entity.id].tags.CREATOR == parseInt(command.attributes.entity)) && entity.tags.ZONE == 6
					# console.log '\tadding entity', entity, @entities[entity.id]
					choices.push entity

			# Taken into accoutn the double discover from fandral
			currentIndex = 0
			while choices.length >= currentIndex + numberOfChoices
				actionChoices = choices.slice currentIndex, currentIndex + numberOfChoices
				action = {
					turn: @currentTurnNumber - 1
					timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
					actionType: 'discover'
					data: @entities[command.attributes.entity]
					owner: @getController(@entities[command.attributes.entity].tags.CONTROLLER)
					choices: actionChoices
					initialCommand: command
				}
				command.isDiscover = true
				@addAction @currentTurnNumber, action
				# console.log 'added discover action', action, @turns[@currentTurnNumber], @turns
				currentIndex += numberOfChoices
				# console.log 'parsing discover action', action, command, choices, actionChoices, @entities[command.attributes.entity], numberOfChoices



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


	parseQuestCompleted: (item) ->
		command = item.node
		if command.attributes.type == '5'
			entity = @entities[command.attributes.entity]
			if entity?.tags?.QUEST == 1
				console.log 'possible quest', command, entity
				if command.fullEntities?.length is 1
					action = {
						turn: @currentTurnNumber - 1
						timestamp: tsToSeconds(command.attributes.ts) || item.timestamp
						actionType: 'quest-completed'
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



	parseMinionCasting: (item) ->
		command = item.node
		if command.tag == 'CAST_RANDOM_SPELLS'
			if command.value is 1
				@minionCasting = parseInt(command.entity)
				console.log 'in minion casting mode'
			else
				@minionCasting = undefined
				console.log 'ending minion casting mode'



	parseEndGame: (item) ->
		command = item.node
		if command.tag == 'PLAYSTATE' and command.value in [4, 5, 6]
			# console.log 'parsing end game', item
			lastAction = _.last @turns[@currentTurnNumber]?.actions
			if lastAction?.actionType is 'end-game'
				lastAction.index = command.index
				lastAction.timestamp = item.timestamp
			else
				action = {
					turn: @currentTurnNumber
					timestamp: item.timestamp
					index: command.index
					actionType: 'end-game'
					mainAction: command.parent?.parent # It's a tag change, so we are interesting in the enclosing action
					initialCommand: command
				}
				@addAction @currentTurnNumber, action

module.exports = ActionParser
