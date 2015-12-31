Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
_ = require 'lodash'
EventEmitter = require 'events'

class ReplayPlayer extends EventEmitter
	constructor: (@parser) ->
		EventEmitter.call(this)

		window.replay = this

		@turns = {
			length: 0
		}
		@currentTurn = 0
		@currentActionInTurn = 0
		@turnLog = ''

	init: ->
		@entities = {}
		@players = []

		@game = null
		@player = null
		@opponent = null

		@history = []
		@historyPosition = 0
		@lastBatch = null

		@startTimestamp = null
		@currentReplayTime = 200

		@started = false

		@cardUtils = window['parseCardsText']
		#console.log 'cardUtils', @cardUtils

		@parser.parse(this)

		@finalizeInit()

		@goNextAction()

	start: (timestamp) ->
		# The timestamp recorded by the game for the beginning, don't touch this
		@startTimestamp = timestamp
		@started = true

	play: ->
		@goToTimestamp @currentReplayTime

	goNextAction: ->
		@newStep()
		@turnLog = ''
		@currentActionInTurn++

		console.log 'goNextAction', @turns[@currentTurn], @currentActionInTurn, if @turns[@currentTurn] then @turns[@currentTurn].actions
		# Navigating within the same turn
		if (@turns[@currentTurn] && @currentActionInTurn <= @turns[@currentTurn].actions.length - 1)
			console.log 'going to next action', @currentActionInTurn, @turns[@currentTurn].actions
			@goToAction()

		# Going to the next turn
		else 
			console.log 'going directly to next turn', @currentTurn + 1
			@goNextTurn()


	goPreviousAction: ->
		@newStep()
		@turnLog = ''
		@currentActionInTurn--
		console.log 'going to previous action', @currentActionInTurn

		if @currentActionInTurn == 1
			console.log 'going directly to beginning of turn', @currentTurn
			@goPreviousTurn()
			@goNextTurn()

		else if @currentActionInTurn <= 0
			console.log 'going directly to end of previous turn', @currentTurn - 1
			@goPreviousTurn()
			console.log 'moved back to previous turn', @currentTurn
			@currentActionInTurn = @turns[@currentTurn].actions.length - 1
			if @currentActionInTurn > 0
				console.log 'moving to action', @currentActionInTurn
				@goToAction()

		# Navigating within the same turn
		else if @turns[@currentTurn]
			@goToAction()
			

	goToAction: ->
		@newStep()
		action = @turns[@currentTurn].actions[@currentActionInTurn]
		console.log 'action', @currentActionInTurn, @turns[@currentTurn], @turns[@currentTurn].actions[@currentActionInTurn]
		targetTimestamp = 1000 * (action.timestamp - @startTimestamp) + 1
		console.log 'executing action', action, action.data
		card = if action?.data then action.data['cardID'] else ''

		owner = action.owner.name 
		if !owner
			ownerCard = @entities[action.owner]
			console.log 'ownerCard', ownerCard, action.owner
			console.log '\tcardID', ownerCard.cardID
			console.log '\treal card', @cardUtils.getCard(ownerCard.cardID)
			owner = @cardUtils.localizeName(@cardUtils.getCard(ownerCard.cardID))
			console.log '\tlocalized name', owner
		@turnLog = owner + action.type + @cardUtils.localizeName(@cardUtils.getCard(card))

		if action.target
			target = @entities[action.target]
			@targetSource = action?.data.id
			@targetDestination = target.id
			@turnLog += ' -> ' + @cardUtils.localizeName(@cardUtils.getCard(target.cardID))

		console.log @turnLog

		@goToTimestamp targetTimestamp

	goNextTurn: ->
		@newStep()
		@currentActionInTurn = 0
		@currentTurn++;
		if @turns[@currentTurn].turn is 'Mulligan'
			@turnLog = @turns[@currentTurn].turn
		else 
			@turnLog = 't' + @turns[@currentTurn].turn + ': ' + @turns[@currentTurn].activePlayer.name

		targetTimestamp = @getTotalLength() * 1000

		# Directly go after the card draw
		if (@currentTurn <= @turns.length && @turns[@currentTurn].actions && @turns[@currentTurn].actions.length > 0)
			@currentActionInTurn = 1
			targetTimestamp = 1000 * (@turns[@currentTurn].actions[@currentActionInTurn].timestamp - @startTimestamp) + 1
		else
			targetTimestamp = 1000 * (@turns[@currentTurn].timestamp - @startTimestamp) + 1

		@goToTimestamp targetTimestamp

	goPreviousTurn: ->
		@newStep()
		# Directly go after the card draw
		@currentActionInTurn = 0
		@currentTurn--;
		console.log 'going to previous turn', @currentTurn, @currentActionInTurn

		targetTimestamp = @getTotalLength() * 1000

		if (@currentTurn <= 0)
			targetTimestamp = 0
			@currentTurn = 0
		# Directly go after the card draw
		else if (@currentTurn <= @turns.length && @turns[@currentTurn].actions && @turns[@currentTurn].actions.length > 0)
			@currentActionInTurn = 1
			targetTimestamp = 1000 * (@turns[@currentTurn].actions[@currentActionInTurn].timestamp - @startTimestamp) + 1
		else
			targetTimestamp = 1000 * (@turns[@currentTurn].timestamp - @startTimestamp) + 1

		if @turns[@currentTurn].turn is 'Mulligan'
			@turnLog = @turns[@currentTurn].turn
		else 
			@turnLog = 't' + @turns[@currentTurn].turn + ': ' + @turns[@currentTurn].activePlayer.name

		@goToTimestamp targetTimestamp

		console.log 'at previous turn', @currentTurn, @currentActionInTurn, @turnLog

	newStep: ->
		@targetSource = undefined
		@targetDestination = undefined

	getTotalLength: ->
		return @history[@history.length - 1].timestamp - @startTimestamp

	getElapsed: ->
		@currentReplayTime / 1000

	getTimestamps: ->
		return _.map @history, (batch) => batch.timestamp - @startTimestamp

	moveTime: (progression) ->
		target = @getTotalLength() * progression * 1000
		@goToTimestamp target

	goToTimestamp: (timestamp) ->
		#console.log 'going to timestamp', timestamp
		#initialSpeed = @speed

		if (timestamp < @currentReplayTime)
			@currentReplayTime = timestamp
			@historyPosition = 0
			@init()

		@start(@startTimestamp)

		#if (!@interval)
			#@run()
			#@changeSpeed(initialSpeed)

		@currentReplayTime = timestamp
		@update()

		@emit 'moved-timestamp'

	update: ->
		#@currentReplayTime += @frequency * @speed
		if (@currentReplayTime >= @getTotalLength() * 1000)
			@currentReplayTime = @getTotalLength() * 1000

		elapsed = @getElapsed()
		while @historyPosition < @history.length
			if elapsed > @history[@historyPosition].timestamp - @startTimestamp
				console.log 'processing', @history[@historyPosition]
				@history[@historyPosition].execute(this)
				@historyPosition++
			else
				break
		#console.log 'stopped at history', @history[@historyPosition].timestamp, elapsed

	receiveGameEntity: (definition) ->
		#console.log 'receiving game entity', definition
		entity = new Entity(this)
		@game = @entities[definition.id] = entity
		entity.update(definition)

	receivePlayer: (definition) ->
		#console.log 'receiving player', definition
		entity = new Player(this)
		@entities[definition.id] = entity
		@players.push(entity)
		entity.update(definition)

		if entity.tags.CURRENT_PLAYER
			@player = entity
		else
			@opponent = entity

	mainPlayer: (entityId) ->
		if (!@mainPlayerId && (parseInt(entityId) == 2 || parseInt(entityId) == 3))
			@mainPlayerId = entityId

	finalizeInit: ->

		@goToTimestamp @currentReplayTime
		@update()

		players = [@player, @opponent]
		playerIndex = 0
		#@speed = 0

		# Build the list of turns along with the history position of each
		# TODO extract that to another file
		if (@turns.length == 0)
			turnNumber = 1
			actionIndex = 0
			currentPlayer = players[playerIndex]
			#console.log 'currentPlayer', currentPlayer, players[0]
			for batch, i in @history
				for command, j in batch.commands

					# Mulligan
					# Add only one command for mulligan start, no need for both
					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 2 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
						#console.log 'batch', i, batch
						#console.log '\tcommand', j, command
						@turns[turnNumber] = {
							historyPosition: i
							turn: 'Mulligan'
							timestamp: batch.timestamp || 0
							actions: []
							activePlayer: currentPlayer
						}
						@turns.length++
						turnNumber++
						actionIndex = 0
						currentPlayer = players[++playerIndex % 2]
						#console.log 'batch', i, batch
						#console.log '\tProcessed mulligan, current player is now', currentPlayer
					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 3 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
						currentPlayer = players[++playerIndex % 2]	
						#console.log 'batch', i, batch	
						#console.log '\tProcessed mulligan, current player is now', currentPlayer				

					# Start of turn
					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 1 && command[1][0].tag == 'STEP' && command[1][0].value == 6)
						#console.log 'batch', i, batch
						#console.log '\tcommand', j, command
						@turns[turnNumber] = {
							historyPosition: i
							turn: turnNumber - 1
							timestamp: batch.timestamp
							actions: []
							activePlayer: currentPlayer
						}
						@turns.length++
						turnNumber++
						actionIndex = 0
						currentPlayer = players[++playerIndex % 2]
						#console.log 'batch', i, batch
						#console.log '\tProcessed end of turn, current player is now', currentPlayer

					# Start of turn draw
					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].tag == 'NUM_CARDS_DRAWN_THIS_TURN' && command[1][0].value > 0)
						#console.log 'batch', i, batch
						#console.log '\tcommand', j, command
						# Don't add card draws that are at the beginning of the game
						if @turns[currentTurnNumber]
							action = {
								turn: currentTurnNumber
								index: actionIndex++
								timestamp: batch.timestamp
								type: ' draw: '
								data: @entities[playedCard]
								owner: @entities[command[1][0].entity]
								initialCommand: command[1][0]
							}
							@turns[currentTurnNumber].actions[actionIndex] = action

					# The actual actions
					if (command[0] == 'receiveAction')
						currentTurnNumber = turnNumber - 1
						if (@turns[currentTurnNumber])

							# Played a card
							if (command[1].length > 0 && command[1][0].tags) 

								playedCard = -1
								#console.log 'considering action', currentTurnNumber, command[1][0].tags, command

								for tag in command[1][0].tags
									#console.log '\ttag', tag.tag, tag.value, tag
									if (tag.tag == 'ZONE' && tag.value == 1)
										playedCard = tag.entity

								if (playedCard > -1)
									#console.log 'batch', i, batch
									#console.log '\tcommand', j, command
									#console.log '\t\tadding action to turn', currentTurnNumber, command[1][0].tags, command
									action = {
										turn: currentTurnNumber - 1
										index: actionIndex++
										timestamp: batch.timestamp
										type: ': '
										data: @entities[playedCard]
										owner: @turns[currentTurnNumber].activePlayer
										initialCommand: command[1][0]
									}
									@turns[currentTurnNumber].actions[actionIndex] = action
									#console.log '\t\tadding action to turn', @turns[currentTurnNumber].actions[actionIndex]

							# Deaths. Not really an action, but useful to see clearly what happens
							if command[1].length > 0 and command[1][0].tags and command[1][0].attributes.type == '6' 

								for tag in command[1][0].tags
									# Graveyard
									if (tag.tag == 'ZONE' && tag.value == 4)
										action = {
											turn: currentTurnNumber - 1
											index: actionIndex++
											timestamp: batch.timestamp
											type: ' died '
											owner: tag.entity
											initialCommand: command[1][0]
										}
										@turns[currentTurnNumber].actions[actionIndex] = action

							# Attacked something
							if command[1].length > 0 and parseInt(command[1][0].attributes.target) > 0 and (command[1][0].attributes.type == '1' or !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)
								#console.log 'considering attack', command[1][0]
								action = {
									turn: currentTurnNumber - 1
									index: actionIndex++
									timestamp: batch.timestamp
									type: ': '
									data: @entities[command[1][0].attributes.entity]
									owner: @turns[currentTurnNumber].activePlayer
									target: command[1][0].attributes.target
									initialCommand: command[1][0]
								}
								@turns[currentTurnNumber].actions[actionIndex] = action
								#console.log '\t\tadding attack to turn', @turns[currentTurnNumber].actions[actionIndex]

							# Card powers. Maybe something more than just battlecries?
							# This also includes all effects from spells, which is too verbose. Don't add the action
							# if it results from a spell being played
							if (command[1].length > 0 && command[1][0].attributes.type == '3')

								#console.log 'parent target?', parseInt(command[1][0].parent?.attributes?.target), command[1][0].attributes.entity, command[1][0]

								# If parent action has a target, do nothing
								if parseInt(command[1][0].parent?.attributes?.target) <= 0

									#console.log '\tadding', parseInt(command[1][0].parent?.attributes?.target), command[1][0].attributes.entity, command[1][0]

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
												turn: currentTurnNumber - 1
												index: actionIndex++
												timestamp: batch.timestamp
												prefix: '\t'
												type: ': '
												data: @entities[command[1][0].attributes.entity]
												owner: @turns[currentTurnNumber].activePlayer
												# Don't store the full entity, because it's possible the target 
												# doesn't exist yet when parsing the replay
												# (it's the case for created tokens)
												#@entities[target]
												target: target
												initialCommand: command[1][0]
											}
											@turns[currentTurnNumber].actions[actionIndex] = action


							# Card revealed
							# TODO: Don't add this when a spell is played, since another action already handles this
							if command[1].length > 0 and command[1][0].showEntity and (command[1][0].attributes.type == '1' or !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)

								#console.log 'considering action for entity ' + command[1][0].showEntity.id, command[1][0].showEntity.tags, command[1][0]
								playedCard = -1

								# Revealed entities can start in the PLAY zone
								for entityTag, tagValue of command[1][0].showEntity.tags
									#console.log '\t\tLooking at ', entityTag, tagValue
									if (entityTag == 'ZONE' && tagValue == 1)
										playedCard = command[1][0].showEntity.id

								# Don't consider mulligan choices for now
								for tag in command[1][0].tags
									#console.log '\ttag', tag.tag, tag.value, tag
									if (tag.tag == 'ZONE' && tag.value == 1)
										playedCard = tag.entity

								if (playedCard > -1)
									#console.log '\tconsidering further'
									action = {
											turn: currentTurnNumber - 1
											index: actionIndex++
											timestamp: batch.timestamp
											type: ': '
											data: if @entities[command[1][0].showEntity.id] then @entities[command[1][0].showEntity.id] else command[1][0].showEntity
											owner: @turns[currentTurnNumber].activePlayer
											debugType: 'showEntity'
											debug: command[1][0].showEntity
											initialCommand: command[1][0]
									}
									if (action.data)
										#console.log 'batch', i, batch
										#console.log '\tcommand', j, command
										#console.log '\t\tadding showEntity', command[1][0].showEntity, action
										@turns[currentTurnNumber].actions[actionIndex] = action

					## Populate relevant data for cards
					if (command[0] == 'receiveShowEntity')
						if (command[1].length > 0 && command[1][0].id && @entities[command[1][0].id]) 
							@entities[command[1][0].id].cardID = command[1][0].cardID
							#console.log 'batch', i, batch
							#console.log '\tcommand', j, command
							#console.log '\t\tUpdated entity', @entities[command[1][0].id]



			console.log @turns.length, 'game turns at position', @turns

		# Find out who is the main player (the one who recorded the game)
		# We use the revealed cards in hand to know this
		#console.log 'finalizing init, player are', @player, @opponent, @players
		if (parseInt(@opponent.id) == parseInt(@mainPlayerId))
			tempOpponent = @player
			@player = @opponent
			@opponent = tempOpponent
		@emit 'players-ready'

	receiveEntity: (definition) ->
		#console.log 'receiving entity', definition
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition)
		if definition.id is 77
			console.log 'receving Squire token', definition, entity
			#if definition.cardID is 'GAME_005'
			#	@player = entity.getController()
			#	@opponent = @player.getOpponent()
			#else
			#	@opponent = entity.getController()
			#	@player = @opponent.getOpponent()

	receiveTagChange: (change) ->
		tags = {}
		tags[change.tag] = change.value

		if @entities[change.entity]
			entity = @entities[change.entity]
			entity.update tags: tags
		else
			entity = @entities[change.entity] = new Entity {
				id: change.entity
				tags: tags
			}, this

	receiveShowEntity: (definition) ->
		#console.log 'receiving show entity', definition
		if @entities[definition.id]
			@entities[definition.id].update(definition)
		else
			@entities[definition.id] = new Entity(definition, this)

	receiveAction: (definition) ->

	receiveOptions: ->

	receiveChoices: (choices) ->

	receiveChosenEntities: (chosen) ->

	enqueue: (timestamp, command, args...) ->
		if not timestamp and @lastBatch
			@lastBatch.addCommand([command, args])
		else
			@lastBatch = new HistoryBatch(timestamp, [command, args])
			@history.push(@lastBatch)
		return @lastBatch

module.exports = ReplayPlayer
