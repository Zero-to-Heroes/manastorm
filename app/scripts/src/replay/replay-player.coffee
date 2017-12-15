
Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
HistoryItem = require './history-item'
ActionParser = require './action-parser'
_ = require 'lodash'
EventEmitter = require 'events'
HSReplayParser = require './parsers/hs-replay'

class ReplayPlayer extends EventEmitter
	constructor: (@parser, @conf) ->
		EventEmitter.call(this)
		@emitter = new EventEmitter

		window.replay = this

		@currentTurn = 0
		@currentActionInTurn = 0
		@initializing = false
		@cardUtils = window['parseCardsText']
		# console.log 'constructor done'


	reload: (xmlReplay, callback) ->
		console.log 'reloading'
		@parser.xmlReplay = xmlReplay
		# EventEmitter.call(this)
		# console.log 'init parser', @parser, xmlReplay
		@currentTurn = 0
		@currentActionInTurn = 0
		@entities = {}
		@newStep()
		# console.log 'reload done'

		@init()

		if callback
			console.log 'calling reload callback'
			callback()


	init: ->
		console.log 'trying to init'
		if @initializing
			setTimeout () =>
				@init()
			, 50
			return

		console.log 'init starting'

		@initializing = true

		if @entities
			for k,v of @entities
				v.damageTaken = 0
				v.healingDone = 0
				v.highlighted = false

		@entities = {}
		@players = []
		@emit 'reset'

		console.log 'starting init in manastorm', @players

		@game = null
		@mainPlayerId = null
		@player = null
		@opponent = null
		@activeSpell = null

		@history = []
		@historyPosition = 0
		@lastBatch = null

		@frequency = 2000
		@currentReplayTime = 0

		@started = false
		@speed = 0
		@previousSpeed = 0
		clearInterval @interval

		@turns = {
			length: 0
		}

		# console.log 'retrieving cardUtils'

		@buildCardLink = @cardUtils.buildCardLink

		# console.log 'checking xmlReplay'
		if !@parser.xmlReplay
			@initializing = false
			return

		@parser.parse(this)
		# console.log 'parsing done'

		# Trigger the population of all the main game entities
		@initializeGameState()
		@fixFirstPlayer()
		# console.log 'initializeGameState done', @players

		# Parse the data to build the game structure
		@actionParser = new ActionParser(this)
		@actionParser.populateEntities()
		# console.log 'popuplateEntities done'
		@actionParser.parseActions()
		# console.log 'parseActions done', @mainPlayerId, this

		# Adjust who is player / opponent
		if (parseInt(@opponent.id) == parseInt(@mainPlayerId))
			@switchMainPlayer()
		# console.log 'switchMainPlayer done', @players

		# Notify the UI controller
		# @emit 'game-generated', this
		# @emit 'players-ready'

		# Preload the images
		images = @buildImagesArray()
		@preloadPictures images

		# console.log 'preloadPictures done'

		# @updateActionsInfo()

		# @finalizeInit()
		# And go to the fisrt action
		# @currentActionInTurn = 0
		# @historyPosition = 0
		@goNextAction()
		# console.log 'notifying changed turn', @players
		@notifyChangedTurn @turns[@currentTurn].turn

		@initializing = false
		console.log 'init done in manastorm', @turns, @players


	autoPlay: ->
		@speed = @previousSpeed || 1
		# console.log 'in autoPlay', @previousSpeed, @speed
		if @speed > 0
			@interval = setInterval((=> @goNextAction()), @frequency / @speed)
			# console.log 'speed > 0', @interval

	pause: ->
		if @speed > 0
			@previousSpeed = @speed
			# console.log 'speed was > 0, storing previous speed', @previousSpeed
		@speed = 0
		# console.log 'pausing', @previousSpeed, @speed, @interval
		clearInterval(@interval)
		# console.log 'cleared interval', @interval

	changeSpeed: (speed) ->
		# console.log 'changing speed'
		@speed = speed
		clearInterval(@interval)
		@interval = setInterval((=> @goNextAction()), @frequency / @speed)

	getCurrentTurnString: ->
		if @turns[@currentTurn].turn is 'Mulligan'
			return 'Mulligan'
		else if @isEndGame
			return 'End game'
		# else if @getActivePlayer() == @player
		# 	return 'Turn ' + Math.ceil((@turns[@currentTurn].turn + @turnOffset) / 2)
		else
			return 'Turn ' + Math.ceil((@turns[@currentTurn].turn + @turnOffset) / 2)

	getCurrentTurn: ->
		# console.log 'getting current turn', @turns[@currentTurn]
		currentTurn = @turns[@currentTurn].turn

		if currentTurn in ['Mulligan', 'mulligan']
			currentTurn = 0

		else if currentTurn is 'endgame'
			currentTurn = 500

		return currentTurn



	# ========================
	# Moving inside the replay (with player controls)
	# ========================
	goNextAction: ->
		actionIndex = @currentActionInTurn
		console.log 'goNextAction', @currentTurn, actionIndex, @historyPosition, @history[@historyPosition].index, @turns, @turns.length, @turns[@currentTurn]

		## last acation in the game
		if @currentTurn == @turns.length and @currentActionInTurn >= @turns[@currentTurn].actions.length - 1
			# console.log 'doing nothing, end of the game', @currentTurn, @turns.length, actionIndex, @turns[@currentTurn].actions.length - 1
			return null

		@newStep()
		@currentActionInTurn++

		# console.log 'goNextAction', @turns[@currentTurn], @currentActionInTurn, if @turns[@currentTurn] then @turns[@currentTurn].actions
		# Navigating within the same turn
		if @turns[@currentTurn] && @currentActionInTurn <= @turns[@currentTurn].actions.length - 1
			@goToAction()

		# Going to the next turn
		else if @turns[@currentTurn + 1]
			@currentTurn++
			# console.log 'goign to next turn', @currentTurn, @turns[@currentTurn]
			@currentActionInTurn = -1

			if !@turns[@currentTurn]
				return

			# console.log 'emitting new turn event',  @turns[@currentTurn]
			@emit 'new-turn', @turns[@currentTurn]
			@notifyChangedTurn @turns[@currentTurn].turn
			@emitter.emit 'new-turn', @turns[@currentTurn]

			index = @turns[@currentTurn].index
			i = 0
			while !index and @turns[@currentTurn].actions and i < @turns[@currentTurn].actions.length
				index = @turns[@currentTurn].actions[i].index

			if index
				@goToIndex index
			# This can happen because of the fake turns introduced to simulate mulligans in spectate mode
			else
				return @goNextAction()

		return true

	goNextTurn: ->
		# console.log 'going to next turn', @currentTurn + 1
		if @turns[@currentTurn + 1]
			turnWhenCommandIssued = @currentTurn

			while turnWhenCommandIssued == @currentTurn
				@goNextAction()
		else
			@goToEndGame()


	goToEndGame: ->
		# console.log 'in goToEndGame'
		while !@isEndGame
			@goNextAction()

		@notifyChangedTurn 'endgame'


	goPreviousAction: (lastIteration) ->
		# console.log 'going to previous action', @currentTurn, @currentActionInTurn, @historyPosition, lastIteration, @turns
		@newStep()
		# todo handle this properly - find out what action should be running at this stage, and update the active spell accordingly
		# for now removing it to avoid showing incorrect things
		@previousActiveSpell = undefined

		if @currentActionInTurn == -1 and @currentTurn > 2
			# console.log 'rolling back to previous turn', @turns, @currentTurn - 1, @turns[@currentTurn - 1].actions.length - 1
			rollbackAction = @turns[@currentTurn - 1].actions[@turns[@currentTurn - 1].actions.length - 1]

		else
			rollbackAction = @turns[@currentTurn].actions[@currentActionInTurn]


		# Update the new action
		if @currentActionInTurn == 1
			targetTurn = @currentTurn
			targetAction = 0

		# Go to Mulligan
		else if @currentActionInTurn < 0 and @currentTurn <= 2
			@moveToStart()
			@currentTurn = 0
			@currentActionInTurn = 0
			console.log 'init because of going to previous action', @currentActionInTurn, @currentTurn
			@init()
			return

		else if @currentActionInTurn < 0
			# console.log 'targeting end of previous turn. Previous turn is', @turns[@currentTurn - 1]
			targetTurn = @currentTurn - 1
			targetAction = @turns[targetTurn].actions.length - 1
			changeTurn = true
			# console.log 'emitting new turn event',  @turns[targetTurn]
			@notifyChangedTurn @turns[@currentTurn].turn
			# Removing the "turn" action log
			# console.log 'going to previous turn', lastIteration
			@emit 'previous-action', rollbackAction

		else
			targetTurn = @currentTurn
			targetAction = @currentActionInTurn - 1

		# console.log '\trolling back action', rollbackAction, @currentTurn, @currentActionInTurn
		@rollbackAction rollbackAction
		@notifyChangedTurn @turns[@currentTurn].turn

		if @currentActionInTurn >= 0 and (!rollbackAction.shouldExecute or rollbackAction.shouldExecute())
			@emit 'previous-action', rollbackAction

		@currentActionInTurn = targetAction
		@currentTurn = targetTurn

		if rollbackAction.shouldExecute and !rollbackAction.shouldExecute() and !changeTurn
			# console.log 'action should not execute, propagating rollback', rollbackAction, lastIteration
			@goPreviousAction lastIteration

		else if !lastIteration
			# console.log 'doing back to handle targeting and stuff'
			@goPreviousAction true
		# hack to handle better all targeting, active spell and so on
		# ultimately all the info should be contained in the action itself and we only read from it
		else
			# hack - because soem tags are only processed with the initial action of the turn, and otherwise we don't go back far enough
			if @currentActionInTurn is -1
				# console.log 'position back to start of turn'
				while @history[@historyPosition] and @history[@historyPosition].index > @turns[@currentTurn].index
					@historyPosition--
				# console.log '\tdone'
			# console.log 'doing forth to handle targeting and stuff'
			@goNextAction()


	goPreviousTurn: ->
		# console.log 'going to previous turn'
		if @turns[@currentTurn - 1]
			# console.log 'previous turn exists', @turns[@currentTurn - 1], @turns, @currentTurn
			turnWhenCommandIssued = @currentTurn

			if turnWhenCommandIssued == 2
				# console.log 'going to previous action'
				@goPreviousAction()
			else
				while @currentTurn >= turnWhenCommandIssued - 1
					# console.log 'going to previous action', @currentTurn, turnWhenCommandIssued
					@goPreviousAction()

				@goNextAction()

	goToAction: ->
		console.log 'going to action', @currentActionInTurn, @currentTurn, @turns[@currentTurn].actions[@currentActionInTurn], @turns[@currentTurn], @turns
		if @currentActionInTurn >= 0
			# console.log 'going to action', @currentActionInTurn, @turns[@currentTurn].actions
			action = @turns[@currentTurn].actions[@currentActionInTurn]
			# There are some actions that we can't filter out at construction time (like a minion being returned in hand with Sap)

			# console.log 'will execute action', action
			@updateActiveSpell action
			@updateEndGame action
			@updateSecret action
			@updateQuest action

			# We only transmit a new event if the action is actually executed
			if !action.shouldExecute or action.shouldExecute()
				@emit 'new-action', action


			if action.target
				@targetSource = action?.data.id
				@targetDestination = action.target
				# console.log 'setting target destination', @targetDestination, @targetSource, action
				@targetType = action.actionType

			# Now we want to go to the action, and to show the effects of the action - ie all
			# that happens until the next action. Otherwise the consequence of an action would
			# be bundled with the next action, which is less intuitive
			nextActionIndex = 1
			nextAction = @turns[@currentTurn].actions[@currentActionInTurn + nextActionIndex]
			while nextAction and (nextAction.shouldExecute and !nextAction.shouldExecute())
				# console.log 'next action is skipping', nextAction, nextAction.shouldExecute
				# Still need to call update() to populate the rollback properly
				index = nextAction.index - 1
				@goToIndex index, @currentTurn, @currentActionInTurn + nextActionIndex, true
				nextAction = @turns[@currentTurn].actions[@currentActionInTurn + ++nextActionIndex]

			# console.log 'nextAction', nextAction
			if nextAction
				index = nextAction.index - 1
			else if @turns[@currentTurn + 1]
				index = @turns[@currentTurn + 1].index - 1
			else
				index = @history[@history.length - 1].index

			# console.log 'index', index

			if action.actionType == 'discover'
				@discoverAction = action
				@discoverController = @getController(@entities[action.data.id].tags.CONTROLLER)
			else if action.actionType == 'splash-reveal'
				@splashEntity = @entities[action.data.id]

			@goToIndex index

			# We already decided that some actions shouldn't execute, so we don't recompute that.
			# -1 is to place the cursor at the step we're actually are, and let the "next action" move the cursor to the
			# action that should actually be executed
			@currentActionInTurn = @currentActionInTurn + (nextActionIndex - 1)


	goToTurn: (gameTurn) ->
		targetTurn = parseInt(gameTurn)
		# console.log 'going to turn', targetTurn

		if targetTurn > @currentTurn
			while targetTurn > @currentTurn
				@goNextTurn()

		else if targetTurn < @currentTurn
			while targetTurn < @currentTurn
				@goPreviousTurn()

		else
			while @currentActionInTurn >= 0
				@goPreviousAction()

	getTurnLabel: (inputTurnNumber) ->
		# console.log 'getting turn label', inputTurnNumber
		# Backward-compatibility
		if !isFinite(inputTurnNumber)
			if '00mulligan' is inputTurnNumber
				return 'mulligan'
			if 'ZZendgame' is inputTurnNumber
				return 'endgame'
			# console.log 'non-numeric turn', inputTurnNumber
			return inputTurnNumber

		inputTurnNumber = parseInt(inputTurnNumber)
		if inputTurnNumber is 0
			turnLabel = 'mulligan'

		else if inputTurnNumber is 500
			turnLabel = 'endgame'

		else if @turns[2].activePlayer == @player
			if inputTurnNumber % 2 == 0
				turnLabel = 't' + inputTurnNumber / 2 + 'o'
			else
				turnLabel = 't' + (inputTurnNumber + 1) / 2
		else
			if inputTurnNumber % 2 != 0
				turnLabel = 't' + (inputTurnNumber + 1) / 2 + 'o'
			else
				turnLabel = 't' + inputTurnNumber / 2

		# console.log 'returning ' + turnLabel
		return turnLabel

	getTurnNumberFromLabel: (turn) ->
		if turn in ['mulligan', '00mulligan']
			gameTurn = 0

		else if turn in ['endgame', 'ZZendgame']
			return 500

		else if @turns[2].activePlayer == @player
			if turn.indexOf('o') != -1
				gameTurn = turn.substring(1, turn.length - 1) * 2
			else
				gameTurn = turn.substring(1, turn.length) * 2 - 1
		else
			if turn.indexOf('o') == -1
				gameTurn = turn.substring(1, turn.length) * 2
			else
				gameTurn = turn.substring(1, turn.length - 1) * 2 - 1

		# console.log 'getTurnNumberFromLabel', turn, gameTurn
		return gameTurn

	goToFriendlyTurn: (turn) ->
		# console.log 'going to turn in replay-player', turn

		if turn is 'mulligan' or turn is 0 or turn is '0'
			gameTurn = 1

		else if turn is 'endgame'
			# console.log 'going to endgame'
			@goToEndGame()
			return

		else if @turns[2].activePlayer == @player
			if turn.indexOf('o') != -1
				gameTurn = turn.substring(0, turn.length - 1) * 2 + 1
			else
				gameTurn = turn.substring(0, turn.length) * 2
		else
			if turn.indexOf('o') == -1
				gameTurn = turn.substring(0, turn.length) * 2 + 1
			else
				gameTurn = turn.substring(0, turn.length - 1) * 2

		# console.log 'gameTurn', gameTurn

		@goToTurn gameTurn

	goToIndex: (index, turn, actionIndex, skipping) ->
		# console.log 'going to index', index, @history[@historyPosition].index, @historyPosition, @history[@historyPosition]
		# The -1 is an ugly hack, no idea why sometimes the index is not properly positioned
		if index < @history[@historyPosition].index - 1 and !skipping
			console.log 'init because going to index', index, @historyPosition, @history[@historyPosition]
			@historyPosition = 0
			@init()

		@targetIndex = index
		@update turn, actionIndex

		@emit 'moved-timestamp'

	# ========================
	# Moving inside the replay (with direct timestamp manipulation)
	# ========================
	moveToStart: () ->
		@currentTurn = 0
		@currentActionInTurn = 0
		@init()

	moveTime: (progression) ->
		if progression == 0
			@moveToStart()

		target = @getTotalLength() * progression
		@moveToTimestamp target

	# Interface with the external world
	moveToTimestamp: (timestamp) ->
		# @pause()

		timestamp += @startTimestamp
		# console.log 'moving to timestamp', timestamp, @getCurrentTimestamp(), @turns[@currentTurn]
		# currentTimestamp = @getCurrentTimestamp()
		# @newStep()

		@seeking = true
		# console.log 'moving on the timeline', timestamp, @getCurrentTimestamp()
		# Going forward
		if !@getCurrentTimestamp() or timestamp > @getCurrentTimestamp()
			# console.log '\tforward'
			hasMoved = true
			while hasMoved and (!@getCurrentTimestamp() or timestamp > @getCurrentTimestamp())
				hasMoved = @goNextAction()
				# console.log 'going to next action', hasMoved, @getCurrentTimestamp(), timestamp, @turns[@currentTurn], @currentActionInTurn, @turns
		else if timestamp < @getCurrentTimestamp()
			# console.log '\tbackward'
			# Stop at mulligan
			while @currentTurn > 1 and (!@getCurrentTimestamp() or timestamp < @getCurrentTimestamp())
				# console.log 'going to previous action', @getCurrentTimestamp(), timestamp, @turns[@currentTurn], @currentActionInTurn, @turns
				@goPreviousAction()

		@seeking = false
		@emit 'moved-timestamp'


	getCurrentTimestamp: ->
		if @isEndGame
			timestamp = @turns[@currentTurn].timestamp
			index =  @currentActionInTurn
			index = Math.max index, 0
			while !timestamp and index > 0 # preventing infinite loops
				timestamp = @turns[@currentTurn].actions[index--]?.timestamp

		else if @turns[@currentTurn] is 'Mulligan'
			timestamp = 0

		else if !@turns[@currentTurn].actions[@currentActionInTurn] or !@turns[@currentTurn].actions[@currentActionInTurn].timestamp
			timestamp = @turns[@currentTurn].timestamp
			index = Math.max @currentActionInTurn, 0
			while !timestamp and index < 30 # preventing infinite loops
				timestamp = @turns[@currentTurn].actions[index++]?.timestamp

		else
			timestamp = @turns[@currentTurn].actions[@currentActionInTurn].timestamp
		# console.log '\t\tgetting current timestamp', timestamp
		# if !timestamp
		# 	console.warn '\t\tcould not get timestamp', @turns[@currentTurn], @currentTurn, @currentActionInTurn, @turns, index
		return timestamp



	getActivePlayer: ->
		return @turns[@currentTurn]?.activePlayer || {}

	getCurrentAction: ->
		return @turns[@currentTurn].actions[@currentActionInTurn]

	newStep: ->
		@targetSource = undefined
		@targetDestination = undefined
		@discoverAction = undefined
		@previousActiveSpell = @activeSpell
		@activeSpell = undefined
		@splashEntity = undefined
		@isEndGame = undefined
		# console.log 'new step', @activeSpell, @previousActiveSpell
		for k,v of @entities
			v.damageTaken = v.tags.DAMAGE or 0
			v.highlighted = false

	getTotalLength: ->
		timestamp = null
		i = 1
		while !timestamp and @history.length - i > 0
			timestamp = @history[@history.length - i++]?.timestamp
		# console.log 'getting total length', timestamp, @startTimestamp
		if timestamp
			return timestamp - @startTimestamp
		return null

	getElapsed: ->
		# console.log 'elapsed', @currentReplayTime
		@currentReplayTime

	getTimestamps: ->
		return _.map @history, (batch) => batch.timestamp - @startTimestamp


	update: (turn, actionIndex) ->
		turn = turn || @currentTurn
		actionIndex = actionIndex || @currentActionInTurn

		# console.log 'moving to index', @targetIndex, @historyPosition, @history[@historyPosition]
		while @history[@historyPosition] and @history[@historyPosition].index <= @targetIndex

			# console.log '\tprocessing', @history[@historyPosition], @history[@historyPosition].index, @targetIndex
			# console.log '\t\tturns', @turns[@currentTurn], @currentTurn, @turns
			if @turns[turn]
				action = @turns[turn].actions[actionIndex]

			@history[@historyPosition].execute(this, action)

			if @history[@historyPosition + 1]
				@historyPosition++
			else
				break
			# console.log '\t\tprocessed'

		# console.log 'finished updating', @history[@historyPosition]
		@updateOptions()
		@updateCurrentReplayTime()

	updateCurrentReplayTime: ->
		currentCursor = @historyPosition
		while @history[currentCursor] and !@history[currentCursor].timestamp
			currentCursor--

		if @history[currentCursor]?.timestamp
			@currentReplayTime = @history[currentCursor].timestamp - @startTimestamp
			# console.log '\tupdating currentReplayTime', @currentReplayTime
		else
			# console.log 'could not update currentReplayTime', @history[currentCursor], currentCursor

		# console.log 'update finished'.


	rollbackAction: (action) ->
		# console.log 'going backwards', action
		while @history[@historyPosition] and @history[@historyPosition].index > action.index
			@historyPosition--

		for k, v of action.rollbackInfo
			# console.log '\trolling entity', k, v, @entities[k], action, @historyPosition
			@entities[k].update tags: v

		@updateOptions()
		@updateCurrentReplayTime()

	inMulligan: ->
		return @opponent.tags?.MULLIGAN_STATE < 4 or @player.tags?.MULLIGAN_STATE < 4

	choosing: ->
		# Blur during mulligan
		if @inMulligan()
			return true

		# Same for discover
		if @discoverAction
			return true

		if @isEndGame
			return true

		if @splashEntity
			return true

		return false

	isFatigue: ->
		return @turns[@currentTurn].actions[@currentActionInTurn]?.actionType is 'fatigue-damage'


	updateOptions: (action) ->
		# console.log 'updating options', @historyPosition
		# Use current action and check if there is no parent? IE allow options only when top-level action has resolved?
		if !@history[@historyPosition]?.parent and @getActivePlayer() == @player
			# console.log 'updating options', @history.length, @historyPosition
			currentCursor = @historyPosition
			while currentCursor > 0
				# If going back to previous turn, stop, as it screws the display of possible options
				if @history[currentCursor]?.command is 'receiveTagChange' and @history[currentCursor].node.tag is 'TURN'
					# console.log 'going back in turn so not updating history'
					return
				if @history[currentCursor]?.command is 'receiveOptions'
					# console.log 'updating options?', @history[currentCursor], @history, currentCursor
					@history[currentCursor].execute(this, action)
					return
				currentCursor--
		# console.log 'stopped at history', @history[@historyPosition].timestamp

	updateActiveSpell: (action) ->
		if !action
			return

		realAction = action.mainAction?.associatedAction || action
		mainEntity = action.mainAction?.associatedAction?.data || action.data
		console.log 'updating active spell', action, realAction, mainEntity
		if mainEntity?.tags?.CARDTYPE is 5 and realAction.actionType in ['played-card-from-hand', 'played-card-with-target', 'played-card-by-minion', 'power-target']
			console.log '\tupdating active spell', mainEntity
			@activeSpell = mainEntity

		else if realAction.actionType in ['minion-death', 'secret-revealed', 'quest-completed', 'card-draw']
			console.log '\tstill showing previous spell', @activeSpell, @previousActiveSpell
			@activeSpell = @previousActiveSpell
			@previousActiveSpell = undefined

	updateSecret: (action) ->
		if action.actionType is 'secret-revealed'
			@revealedSecret = action.data
		else
			@revealedSecret = false

	updateQuest: (action) ->
		if action.actionType is 'quest-completed'
			@questCompleted = action.data
		else
			@questCompleted = false

	updateEndGame: (action) ->
		if action.actionType is 'end-game'
			@isEndGame = true
			# console.log 'notifying endgame'
			@notifyChangedTurn 'endgame'
		else
			@isEndGame = false
		# action.activeSpell = @activeSpell

	mainPlayer: (entityId) ->
		if (!@mainPlayerId && (parseInt(entityId) == 2 || parseInt(entityId) == 3))
			# console.log 'setting mainPlayer', entityId, this
			@mainPlayerId = entityId

	switchMainPlayer: ->
		tempOpponent = @player
		@player = @opponent
		@opponent = tempOpponent
		@mainPlayerId = @player.id
		# console.log 'switched main player, new one is', @mainPlayerId, @player

	getController: (controllerId) ->
		# console.log 'getting controller', @player, @opponent, this
		if @player.tags.CONTROLLER == controllerId
			return @player
		return @opponent


	# ==================
	# Initialization
	# ==================
	initializeGameState: ->
		# console.log 'initializing gs'
		# Find the index of the last FullEntity creation
		index = 0
		# Go to first mulligan
		while @history[index]
			if @history[index].command is 'receiveAction'
				lastAction = @history[index]
			# In case we spectate a game, we don't always have the mulligan
			if @history[index].command is 'receiveAction' and @history[index].node.attributes.type == '7'
				# console.log 'stopping gs init because we found a play action', lastAction
				break
			else if @history[index].command is 'receiveTagChange' and @history[index].node.tag is 'MULLIGAN_STATE' and lastAction
				break
			index++

		# console.log 'stopping game state init at ', lastAction
		@goToIndex lastAction.index


	# ==================
	# Processing the different state changes
	# ==================
	receiveGameEntity: (definition) ->
		# console.log 'receiving game entity', definition
		entity = new Entity(this)
		@game = @entities[definition.id] = entity
		entity.update(definition)

	receivePlayer: (definition) ->
		entity = new Player(this)
		# console.log 'receiving player', entity, entity.tags.CURRENT_PLAYER, this
		@entities[definition.id] = entity
		@players.push(entity)
		entity.update(definition)

		if entity.tags.CURRENT_PLAYER
			@player = entity
			# console.log 'setting player', entity, @player
		else
			@opponent = entity
			# console.log 'setting opponent', entity, @opponent

	receiveEntity: (definition, action) ->
		# console.log 'receiving entity', definition.id, definition, @entities[definition.id]
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition, action)
		# if definition.id is 13
		# 	console.log 'receving entity', definition, entity

	receiveTagChange: (change, action) ->

		tags = {}
		tags[change.tag] = change.value

		if @entities[change.entity]
			entity = @entities[change.entity]
			entity.update tags: tags, action
		else
			entity = @entities[change.entity] = new Entity {
				id: change.entity
				tags: tags
			}, this

		# if change.tag is 'MULLIGAN_STATE'
		# 	console.log '\tprocessed tag change', change, @entities[change.entity]

	receiveShowEntity: (definition, action) ->
		console.log '\t\treceiving show entity', definition.id, definition
		if @entities[definition.id]
			@entities[definition.id].update(definition, action)
		else
			@entities[definition.id] = new Entity(definition, this)


	fixFirstPlayer: () =>
		# This happened in TB of 23/11/2017 where the player wasn't guessable at the start of the game
		if (@player is null or @opponent is null or @player is @opponent)
			console.log 'fixing first player'
			for item in @history
				if item.command is 'receiveShowEntity'
					definition = item.node
					if definition.cardID and definition.tags?.CARDTYPE != 6
						# entity = @entities[definition.id]
						# if !entity
						# 	continue

						console.log 'setting player from', definition, item, @entities
						for entityId, candidate of @entities
							if candidate.tags?.CARDTYPE is 2
								player = candidate
								if player.tags.CONTROLLER is definition.tags.CONTROLLER
									@player = player
									# console.log '\tsetting player', @player
								else
									@opponent = player
									# console.log '\tsetting opponent', @opponent
						console.log 'set player and opponent', @player, @opponent
						return

	receiveChangeEntity: (definition, action) ->
		# console.log '\t\treceiving change entity', definition.id, definition
		if @entities[definition.id]
			@entities[definition.id].update(definition, action)
		else
			@entities[definition.id] = new Entity(definition, this)

	receiveAction: (definition) ->
		# console.log '\t\treceiving action', definition
		# if definition.isDiscover
		# 	@discoverAction = definition
		# 	@discoverController = @getController(@entities[definition.attributes.entity].tags.CONTROLLER)
		# console.log 'received action"'

	receiveOptions: (options) ->
		# console.log '\t\treceiving options', options

		for k,v of @entities
			v.highlighted = false

		for option in options.options
			# console.log 'highlighting', @entities[option.entity], option
			# Older games don't have the error attribute on options
			if !option.error or option.error is -1
				@entities[option.entity]?.highlighted = true
			# @entities[option.entity]?.emit 'option-on'

	receiveChoices: (choices) ->

	receiveChosenEntities: (chosen) ->

	enqueue: (command, node, timestamp) ->
		item = new HistoryItem(command, node, timestamp)
		@history.push(item)




	# ==================
	# Communication with other entities
	# ==================
	forceReemit: ->
		@emit 'new-turn', @turns[@currentTurn]

	notifyNewLog: (log) ->
		@emit 'new-log', log

	notifyChangedTurn: (inputTurnNumber) ->
		# console.log 'notifying changed turn', inputTurnNumber
		if inputTurnNumber in ['Mulligan', 'mulligan']
			turnNumber = 0 #'mulligan'

		else if inputTurnNumber is 'endgame'
			turnNumber = 500 #'endgame'

		# console.log 'final turn', turnNumber
		@onTurnChanged? if turnNumber isnt undefined then turnNumber else inputTurnNumber



	getPlayerInfo: ->
		# console.log 'getting player info', @opponent, @entities[@opponent.tags.HERO_ENTITY], @getClass(@entities[@opponent.tags.HERO_ENTITY].cardID)
		playerInfo = {
			player: {
				'name': @player.name,
				'class': @getClass(@entities[@player.tags.HERO_ENTITY].cardID)
			},
			opponent: {
				'name': @opponent.name,
				'class': @getClass(@entities[@opponent.tags.HERO_ENTITY].cardID)
			}
		}

		return playerInfo

	getClass: (cardID) ->
		return @cardUtils.getCard(cardID)?.playerClass?.toLowerCase()

	isValid: ->
		return if !@getClass(@entities[@player.tags.HERO_ENTITY].cardID) then false else true

		# console.log 'preloaded images'

	# Replace the tN keywords
	replaceKeywordsWithTimestamp: (text) ->
		# console.log 'looking at text', text
		# https://regex101.com/r/yD6dG8/1
		turnRegex = /(?:\s|^)(?:t(?:urn )?|T(?:urn )?)(\d?\do?)(?:|\s|,|\.|\?|$)/gm
		# opoonentTurnRegex = /(\s|^)(t|T)\d?\do(:|\s|,|\.|\?|$)/gm

		# longTurnRegex = /(\s|^)(turn|Turn)\s?\d?\d(:|\s|,|\.|\?|$)/gm
		# longOpponentTurnRegex = /(\s|^)(turn|Turn)\s?\d?\do(:|\s|,|\.|\?|$)/gm

		mulliganRegex = /(\s|^)(m|M)ulligan(:|\s|\?|$)/gm
		endgameRegex = /(?:\s|^)((?:e|E)nd(?: )?game)(?::|\s|\?|$)/gm

		that = this

		match = turnRegex.exec(text)
		while match
			# console.log '\tmatched!!!', match[1], match
			# console.log 'replaced substring', text.substring(match.index, match.index + match[0].length)
			opponent = match[1].indexOf('o') != -1
			inputTurnNumber = parseInt(match[1])
			text = that.replaceText text, inputTurnNumber, match, opponent, turnRegex
			# console.log 'new text', text
			# Approximate length of the new chain
			match = turnRegex.exec(text)

		match = endgameRegex.exec(text)
		while match
			replaceString = '<a ng-click="mediaPlayer.goToTimestamp(\'endgame\')" class="ng-scope">' + match[0] + '</a>'
			text = text.substring(0, match.index) + replaceString + text.substring(match.index + match[0].length)
			turnRegex.lastIndex += replaceString.length
			match = turnRegex.exec(text)


		matches = text.match(mulliganRegex)
		if matches and matches.length > 0
			matches = _.uniq matches
			matches.forEach (match) ->
				text = text.replace match, '<a ng-click="mediaPlayer.goToTimestamp(\'mulligan\')" class="ng-scope">' + match + '</a>'

		# console.log 'modified text', text
		return text

	replaceText: (text, inputTurnNumber, match, opponent, turnRegex) ->

		# Now compute the "real" turn. This depends on whether you're the first player or not
		if @turns[2].activePlayer == @player
			if opponent
				turnNumber = inputTurnNumber * 2 + 1
			else
				turnNumber = inputTurnNumber * 2
		else
			if !opponent
				turnNumber = inputTurnNumber * 2 + 1
			else
				turnNumber = inputTurnNumber * 2

		if !@turns[turnNumber]
			console.warn 'turn doesnt exist', turnNumber
			return text

		inputTurnNumber = 't' + inputTurnNumber

		if opponent
			inputTurnNumber += 'o'

		replaceString = '<a ng-click="mediaPlayer.goToTimestamp(\'' + inputTurnNumber + '\')" class="ng-scope">' + match[0] + '</a>'
		text = text.substring(0, match.index) + replaceString + text.substring(match.index + match[0].length)

		turnRegex.lastIndex += replaceString.length
		# console.log 'replacing match', match
		# text = text.replace match, '<a ng-click="mediaPlayer.goToTimestamp(\'' + inputTurnNumber + '\')" class="ng-scope">' + match + '</a>'
		return text

	formatTimeStamp: (length) ->
		totalSeconds = "" + Math.floor(length % 60)
		if totalSeconds.length < 2
			totalSeconds = "0" + totalSeconds
		totalMinutes = Math.floor(length / 60)
		if totalMinutes.length < 2
			totalMinutes = "0" + totalMinutes

		return totalMinutes + ':' + totalSeconds


	# ==================
	# Image preloading
	# ==================
	buildImagesArray: ->
		entities = []
		# Entities are roughly added in the order of apparition
		for k,v of @entities
			entities.push v

		images = []
		for entity in entities
			if entity.cardID
				card = @cardUtils.getCard(entity.cardID)
				# TODO: extract this to its own component, and reuse it from card.cjsx
				if card and card.type != 'Enchantment'
					baseFolder = 'allCards'
					premiumDir = ''
					if entity.tags.PREMIUM is 1 and card?.goldenImage and !@conf?.noGolden
						premiumClass = 'golden'
						premiumDir = 'golden_single_frame/'

						if @conf?.useCompressedImages
							premiumDir = 'golden/'

					if @conf?.useCompressedImages
						baseFolder = 'fullcards/en/256'

					imgUrl = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/#{baseFolder}/#{premiumDir}#{entity.cardID}.png"
					images.push imgUrl

		# console.log 'image array', images
		return images

	preloadPictures: (arrayOfImages) ->
		# console.log 'preloading', arrayOfImages
		arrayOfImages.forEach (img) ->
			# console.log '\tpreloading', img
			(new Image()).src = img


module.exports = ReplayPlayer
