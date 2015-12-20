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
		@turnLog = ''

		@cardUtils = window['parseCardsText']
		console.log 'cardUtils', @cardUtils

		@parser.parse(this)

		@finalizeInit()

	start: (timestamp) ->
		# The timestamp recorded by the game for the beginning, don't touch this
		@startTimestamp = timestamp
		@started = true

	play: ->
		@goToTimestamp @currentReplayTime

	goNextAction: ->
		@turnLog = ''
		console.log 'going to next action', @currentActionInTurn
		@currentActionInTurn++

		targetTimestamp = @getTotalLength() * 1000

		# Navigating within the same turn
		if (@turns[@currentTurn] && @currentActionInTurn <= @turns[@currentTurn].actions.length - 1)
			action = @turns[@currentTurn].actions[@currentActionInTurn]
			targetTimestamp = 1000 * (action.timestamp - @startTimestamp) + 1
			console.log 'executing action', action, action.data
			card = if action?.data then action.data['cardID'] else ''
			@turnLog = action.owner.name + action.type + @cardUtils.localizeName(@cardUtils.getCard(card))
			if action.target
				@turnLog += ' -> ' + @cardUtils.localizeName(@cardUtils.getCard(action.target.cardID))
			console.log @turnLog
			@goToTimestamp targetTimestamp

			@update()

		# Going to the next turn
		else 
			console.log 'going directly to next turn'
			@goNextTurn()


	goPreviousAction: ->
		@turnLog = ''
		console.log 'going to previous action'

	goNextTurn: ->
		@currentActionInTurn = 0
		@currentTurn++;
		@turnLog = 't' + @currentTurn + ': ' + @turns[@currentTurn].activePlayer.name

		targetTimestamp = @getTotalLength() * 1000

		if (@currentTurn <= @turns.length)
			targetTimestamp = 1000 * (@turns[@currentTurn].timestamp - @startTimestamp) + 1

		@goToTimestamp targetTimestamp

		@update()

	goPreviousTurn: ->
		@currentActionInTurn = 0
		@currentTurn--;
		@turnLog = 't' + @currentTurn + ': ' + @turns[@currentTurn].activePlayer.name

		targetTimestamp = @getTotalLength() * 1000

		if (@currentTurn <= 0)
			targetTimestamp = 0
			@currentTurn = 0
		else if (@currentTurn <= @turns.length)
			targetTimestamp = 1000 * (@turns[@currentTurn].timestamp - @startTimestamp) + 1

		@goToTimestamp targetTimestamp
		
		@update()

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
		console.log 'going to timestamp', timestamp
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
				#console.log 'historyPositionTimestamp', @history[@historyPosition].timestamp, elapsed
				@history[@historyPosition].execute(this)
				@historyPosition++
			else
				break
		console.log 'stopped at history', @history[@historyPosition].timestamp, elapsed

	receiveGameEntity: (definition) ->
		console.log 'receiving game entity', definition
		entity = new Entity(this)
		@game = @entities[definition.id] = entity
		entity.update(definition)

	receivePlayer: (definition) ->
		console.log 'receiving player', definition
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
			console.log 'currentPlayer', currentPlayer, players[0]
			for batch, i in @history
				for command, j in batch.commands
					# Mulligan
					# Add only one command for mulligan start, no need for both
					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 2 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
						#console.log 'batch', i, batch
						#console.log '\tcommand', j, command
						@turns[turnNumber] = {
							historyPosition: i
							turn: 'mulligan'
							timestamp: batch.timestamp || 0
							actions: []
							activePlayer: currentPlayer
						}
						@turns.length++
						turnNumber++
						actionIndex = 0
						currentPlayer = players[++playerIndex % 2]
						console.log 'batch', i, batch
						console.log '\tProcessed mulligan, current player is now', currentPlayer

					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 3 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
						currentPlayer = players[++playerIndex % 2]	
						console.log 'batch', i, batch	
						console.log '\tProcessed mulligan, current player is now', currentPlayer				

					# Start of turn
					if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 1 && command[1][0].tag == 'STEP' && command[1][0].value == 6)
						#console.log 'batch', i, batch
						#console.log '\tcommand', j, command
						@turns[turnNumber] = {
							historyPosition: i
							# Drawing the coin is considered a "turn", we probably need to add -1 to match the "real" turn
							turn: turnNumber
							timestamp: batch.timestamp
							actions: []
							activePlayer: currentPlayer
						}
						@turns.length++
						turnNumber++
						actionIndex = 0
						currentPlayer = players[++playerIndex % 2]
						console.log 'batch', i, batch
						console.log '\tProcessed end of turn, current player is now', currentPlayer

					# The actual actions
					if (command[0] == 'receiveAction')
						currentTurnNumber = turnNumber - 1
						if (@turns[currentTurnNumber])
							# Now we need to see if this action does anything useful
							# Played a card
							if (command[1].length > 0 && command[1][0].tags) 

								playedCard = -1
								console.log 'considering action', currentTurnNumber, command[1][0].tags, command

								for tag in command[1][0].tags
									#console.log '\ttag', tag.tag, tag.value, tag
									if (tag.tag == 'ZONE' && tag.value == 1)
										playedCard = tag.entity

								if (playedCard > -1)
									console.log 'batch', i, batch
									console.log '\tcommand', j, command
									#console.log '\t\tadding action to turn', currentTurnNumber, command[1][0].tags, command
									action = {
										turn: currentTurnNumber
										index: actionIndex++
										timestamp: batch.timestamp
										type: ': '
										data: @entities[playedCard]
										owner: @turns[currentTurnNumber].activePlayer
									}
									@turns[currentTurnNumber].actions[actionIndex] = action
									console.log '\t\tadding action to turn', @turns[currentTurnNumber].actions[actionIndex]

							# Attacked something
							if (command[1].length > 0 && parseInt(command[1][0].attributes.target) > 0) 
								console.log 'considering attack', command[1][0]
								action = {
									turn: currentTurnNumber
									index: actionIndex++
									timestamp: batch.timestamp
									type: ': '
									data: @entities[command[1][0].attributes.entity]
									owner: @turns[currentTurnNumber].activePlayer
									target: @entities[command[1][0].attributes.target]
								}
								@turns[currentTurnNumber].actions[actionIndex] = action
								console.log '\t\tadding attack to turn', @turns[currentTurnNumber].actions[actionIndex]


							# Card revealed
							# TODO: Hero Power is considered the same as any card
							if (command[1].length > 0 && command[1][0].showEntity) 

								console.log 'considering action for entity ' + command[1][0].showEntity.id, command[1][0].showEntity.tags, command[1][0]

								playedCard = -1

								# Revealed entities can start in the PLAY zone
								for entityTag, tagValue of command[1][0].showEntity.tags
									console.log '\t\tLooking at ', entityTag, tagValue
									if (entityTag == 'ZONE' && tagValue == 1)
										playedCard = command[1][0].showEntity.id

								# Don't consider mulligan choices for now
								for tag in command[1][0].tags
									console.log '\ttag', tag.tag, tag.value, tag
									if (tag.tag == 'ZONE' && tag.value == 1)
										playedCard = tag.entity

								if (playedCard > -1)
									#console.log '\tconsidering further'
									action = {
											turn: currentTurnNumber
											index: actionIndex++
											timestamp: batch.timestamp
											type: ': '
											data: if @entities[command[1][0].showEntity.id] then @entities[command[1][0].showEntity.id] else command[1][0].showEntity
											owner: @turns[currentTurnNumber].activePlayer
											debug: command[1][0].showEntity
									}
									if (action.data)
										console.log 'batch', i, batch
										console.log '\tcommand', j, command
										console.log '\t\tadding showEntity', command[1][0].showEntity, action
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
		console.log 'finalizing init, player are', @player, @opponent, @players
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
		#if definition.id is 68
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
