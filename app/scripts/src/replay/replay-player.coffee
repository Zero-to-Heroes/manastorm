
Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
HistoryItem = require './history-item'
ActionParser = require './action-parser'
_ = require 'lodash'
EventEmitter = require 'events'
HSReplayParser = require './parsers/hs-replay'

class ReplayPlayer extends EventEmitter
	constructor: (@parser) ->
		EventEmitter.call(this)
		@emitter = new EventEmitter

		window.replay = this

		@currentTurn = 0
		@currentActionInTurn = 0
		@cardUtils = window['parseCardsText']

	reload: (xmlReplay) ->
		@parser.xmlReplay = xmlReplay
		# EventEmitter.call(this)
		# console.log 'init parser', @parser, xmlReplay
		@currentTurn = 0
		@currentActionInTurn = 0
		@entities = {}
		@newStep()

		@init()


	init: ->
		# console.log 'starting init in manastorm'
		if @entities
			for k,v of @entities
				v.damageTaken = 0
				v.healingDone = 0
				v.highlighted = false

		@entities = {}
		@players = []
		@emit 'reset'

		@game = null
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

		@turns = {
			length: 0
		}

		@buildCardLink = @cardUtils.buildCardLink

		if !@parser.xmlReplay
			return

		@parser.parse(this)

		# Trigger the population of all the main game entities
		@initializeGameState()
		# console.log 'initializeGameState done'

		# Parse the data to build the game structure
		@actionParser = new ActionParser(this)
		@actionParser.populateEntities()
		# console.log 'popuplateEntities done'
		@actionParser.parseActions()
		# console.log 'parseActions done'

		# Adjust who is player / opponent
		if (parseInt(@opponent.id) == parseInt(@mainPlayerId))
			@switchMainPlayer()
		# console.log 'switchMainPlayer done'

		# Notify the UI controller
		@emit 'game-generated', this
		# @emit 'players-ready'

		# Preload the images
		images = @buildImagesArray()
		@preloadPictures images
		# console.log 'preloadPictures done'

		# @updateActionsInfo()

		# @finalizeInit()
		# And go to the fisrt action
		@goNextAction()
		# console.log 'init done in manastorm', @turns


	autoPlay: ->
		@speed = @previousSpeed || 1
		if @speed > 0
			@interval = setInterval((=> @goNextAction()), @frequency / @speed)

	pause: ->
		# console.log 'pausing'
		if @speed > 0
			@previousSpeed = @speed
		@speed = 0
		clearInterval(@interval)

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
		else if @getActivePlayer() == @player
			return 'Turn ' + Math.ceil(@turns[@currentTurn].turn / 2)
		else
			return 'Turn ' + Math.ceil(@turns[@currentTurn].turn / 2) + 'o'

	getCurrentTurn: ->
		# console.log 'getting current turn', @turns[@currentTurn]
		if @turns[@currentTurn].turn is 'Mulligan'
			return 'mulligan'
		else if @isEndGame
			return 'endgame'
		else if @getActivePlayer() == @player
			return 't' + Math.ceil(@turns[@currentTurn].turn / 2)
		else
			return 't' + Math.ceil(@turns[@currentTurn].turn / 2) + 'o'



	# ========================
	# Moving inside the replay (with player controls)
	# ========================
	goNextAction: ->
		actionIndex = @currentActionInTurn
		# console.log 'goNextAction', @currentTurn, actionIndex, @historyPosition, @turns, @turns.length, @turns[@currentTurn]

		## last acation in the game
		if @currentTurn == @turns.length and @currentActionInTurn >= @turns[@currentTurn].actions.length - 1
			console.log 'doing nothing, end of the game', @currentTurn, @turns.length, actionIndex, @turns[@currentTurn].actions.length - 1
			return null

		@newStep()
		@currentActionInTurn++

		# console.log 'goNextAction', @turns[@currentTurn], @currentActionInTurn, if @turns[@currentTurn] then @turns[@currentTurn].actions
		# Navigating within the same turn
		if @turns[@currentTurn] && @currentActionInTurn <= @turns[@currentTurn].actions.length - 1
			@goToAction()

		# Going to the next turn
		else if @turns[@currentTurn + 1]
			# console.log 'goign to next turn', @currentTurn + 1
			@currentTurn++
			@currentActionInTurn = -1

			if !@turns[@currentTurn]
				return

			# console.log 'emitting new turn event',  @turns[@currentTurn]
			@emit 'new-turn', @turns[@currentTurn]
			@notifyChangedTurn @turns[@currentTurn].turn
			@emitter.emit 'new-turn', @turns[@currentTurn]

			@goToIndex @turns[@currentTurn].index

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
		console.log 'going to previous action', @currentTurn, @currentActionInTurn, @historyPosition, lastIteration, @turns
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
			@currentTurn = 0
			@currentActionInTurn = 0
			@init()
			return

		else if @currentActionInTurn < 0
			# console.log 'targeting end of previous turn. Previous turn is', @turns[@currentTurn - 1]
			targetTurn = @currentTurn - 1
			targetAction = @turns[targetTurn].actions.length - 1
			changeTurn = true
			# console.log 'emitting new turn event',  @turns[targetTurn]
			@notifyChangedTurn @turns[@currentTurn].turn
			# @emit 'previous-action', rollbackAction
			# Removing the "turn" action log
			console.log 'going to previous turn', lastIteration
			@emit 'previous-action', rollbackAction
			# @emit 'new-turn', @turns[targetTurn]

		else
			targetTurn = @currentTurn
			targetAction = @currentActionInTurn - 1


		# console.log 'rollbackAction', rollbackAction, rollbackAction.shouldExecute, rollbackAction.shouldExecute?()
		# if rollbackAction.shouldExecute and !rollbackAction.shouldExecute() and !changeTurn
		# 	# console.log '\tskipping back', rollbackAction, @currentTurn, @currentActionInTurn, @turns[@currentTurn]
		# 	@currentActionInTurn = targetAction
		# 	@currentTurn = targetTurn
		# 	# @emit 'previous-action', rollbackAction
		# 	@goPreviousAction lastIteration

		# else

			# console.log '\trolling back action', rollbackAction, @currentTurn, @currentActionInTurn
		@rollbackAction rollbackAction
		@notifyChangedTurn @turns[@currentTurn].turn

		# @emit 'previous-action', rollbackAction
		if @currentActionInTurn >= 0 and (!rollbackAction.shouldExecute or rollbackAction.shouldExecute())
			@emit 'previous-action', rollbackAction
		



		# previousAction = @turns[targetTurn].actions[targetAction]
		# @updateActiveSpell previousAction

		# actionBeforeUpdate = @currentActionInTurn
		@currentActionInTurn = targetAction
		@currentTurn = targetTurn

		if rollbackAction.shouldExecute and !rollbackAction.shouldExecute() and !changeTurn
			console.log 'action should not execute, propagating rollback', rollbackAction, lastIteration
			@goPreviousAction lastIteration

		else if !lastIteration
			console.log 'doing back to handle targeting and stuff'
			@goPreviousAction true
			# Go back to the very beginning of turn if appropriate
		# hack to handle better all targeting, active spell and so on
		# ultimately all the info should be contained in the action itself and we only read from it
		else 
			# hack - because soem tags are only processed with the initial action of the turn, and otherwise we don't go back far enough
			if @currentActionInTurn is -1
				# console.log 'position back to start of turn'
				while @history[@historyPosition] and @history[@historyPosition].index > @turns[@currentTurn].index
					@historyPosition--
				# console.log '\tdone'
			console.log 'doing forth to handle targeting and stuff'
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
		console.log 'going to action', @currentActionInTurn, @turns[@currentTurn].actions[@currentActionInTurn]
		if @currentActionInTurn >= 0
			# console.log 'going to action', @currentActionInTurn, @turns[@currentTurn].actions
			action = @turns[@currentTurn].actions[@currentActionInTurn]
			# There are some actions that we can't filter out at construction time (like a minion being returned in hand with Sap)

			# console.log '\tshould execute?', action.shouldExecute?(), action?.fullData?.tags?.ZONE

			# if action.shouldExecute and !action.shouldExecute() 
			# 	if !@seeking
			# 		# console.log 'skipping action', action
			# 		# Still need to call update() to populate the rollback properly
			# 		index = action.index - 1
			# 		@goToIndex index
			# 		@goNextAction()

			# console.log 'will execute action', action
			@updateActiveSpell action
			@updateEndGame action
			@updateSecret action

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
				@goToIndex index, @currentTurn, @currentActionInTurn + nextActionIndex
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
		console.log 'going to turn', targetTurn

		if targetTurn > @currentTurn
			while targetTurn > @currentTurn
				@goNextTurn()

		else if targetTurn < @currentTurn
			while targetTurn < @currentTurn
				@goPreviousTurn()

		else 
			while @currentActionInTurn >= 0
				@goPreviousAction()


	goToFriendlyTurn: (turn) ->
		console.log 'going to turn in replay-player', turn

		if turn is 'mulligan' or turn is 0 or turn is '0'
			gameTurn = 1

		else if turn is 'endgame'
			console.log 'going to endgame'
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

		console.log 'gameTurn', gameTurn

		@goToTurn gameTurn

	goToIndex: (index, turn, actionIndex) ->
		# console.log 'going to index', index
		if index < @historyPosition
			@historyPosition = 0
			@init()

		@targetIndex = index
		@update turn, actionIndex

		@emit 'moved-timestamp'

	# ========================
	# Moving inside the replay (with direct timestamp manipulation)
	# ========================
	moveTime: (progression) ->
		target = @getTotalLength() * progression
		@moveToTimestamp target

	# Interface with the external world
	moveToTimestamp: (timestamp) ->
		@pause()

		timestamp += @startTimestamp
		console.log 'moving to timestamp', timestamp, @getCurrentTimestamp(), @turns[@currentTurn]
		@newStep()

		# lastTimestamp = 0
		# index = 0
		# while !lastTimestamp or (lastTimestamp < timestamp)
		# 	lastTimestamp = @history[++index].timestamp

		# Going forward
		@seeking = true
		# console.log 'moving on the timeline', timestamp, @getCurrentTimestamp()
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
			# console.log '\tprocessing', @historyPosition, @targetIndex, @history[@historyPosition], @history[@historyPosition + 1]
			# console.log '\t\tturns', @turns[@currentTurn], @currentTurn, @turns
			if @turns[turn]
				action = @turns[turn].actions[actionIndex]

			@history[@historyPosition].execute(this, action)

			if @history[@historyPosition + 1]
				@historyPosition++
			else 
				break
			# console.log '\t\tprocessed'


		@updateOptions()
		if @history[@historyPosition - 1]?.timestamp
			@currentReplayTime = @history[@historyPosition - 1].timestamp - @startTimestamp
			# console.log '\tupdating timestamp', @currentReplayTime

		# console.log 'update finished'.


	rollbackAction: (action) ->
		# console.log 'going backwards', action
		while @history[@historyPosition] and @history[@historyPosition].index > action.index
			@historyPosition--

		for k, v of action.rollbackInfo
			# console.log '\trolling entity', k, v, @entities[k], action, @historyPosition
			@entities[k].update tags: v

		@updateOptions()
		if @history[@historyPosition - 1]?.timestamp
			@currentReplayTime = @history[@historyPosition - 1].timestamp - @startTimestamp
			# console.log '\tupdating timestamp', @currentReplayTime

	choosing: ->
		# Blur during mulligan
		if @turns[@currentTurn].turn is 'Mulligan'
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
		# console.log 'updating options'
		# Use current action and check if there is no parent? IE allow options only when top-level action has resolved?
		if !@history[@historyPosition]?.parent and @getActivePlayer() == @player
			# console.log 'updating options', @history.length, @historyPosition
			currentCursor = @historyPosition
			while currentCursor > 0
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
		# console.log 'updating active spell', action, realAction, mainEntity
		if mainEntity?.tags?.CARDTYPE is 5 and realAction.actionType in ['played-card-from-hand', 'played-card-with-target']
			# console.log '\tupdating active spell', mainEntity
			@activeSpell = mainEntity

		else if realAction.actionType in ['minion-death', 'secret-revealed', 'card-draw']
			# console.log '\tstill showing previous spell', @activeSpell, @previousActiveSpell
			@activeSpell = @previousActiveSpell
			@previousActiveSpell = undefined

	updateSecret: (action) ->
		if action.actionType is 'secret-revealed'
			@revealedSecret = action.data
		else 
			@revealedSecret = false

	updateEndGame: (action) ->
		if action.actionType is 'end-game'
			@isEndGame = true
			console.log 'notifying endgame'
			@notifyChangedTurn 'endgame'
		else 
			@isEndGame = false
		# action.activeSpell = @activeSpell

	mainPlayer: (entityId) ->
		if (!@mainPlayerId && (parseInt(entityId) == 2 || parseInt(entityId) == 3))
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
		# Find the index of the last FullEntity creation
		index = 0
		# Go to first mulligan
		while @history[index]
			if @history[index].command is 'receiveAction'
				lastAction = @history[index]
			if @history[index].command is 'receiveTagChange' and @history[index].node.tag is 'MULLIGAN_STATE'
				break
			index++

		# while @history[index].command isnt 'receiveAction'
		# 	# console.log '\tSkipping to first action', index
		# 	index++			
		# 	# console.log index, @history[index], @history
		# index++
		# # console.log index, @history[index], @history
		# while @history[index].command isnt 'receiveAction'
		# 	# console.log '\tSkipping to secdon action', index
		# 	index++
		# 	# console.log index, @history[index], @history
		# console.log 'last index before action', index, @history[index], @history[index + 1]
		# @goToIndex @history[index].index
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
		@entities[definition.id] = entity
		@players.push(entity)
		entity.update(definition)
		# console.log 'receiving player', entity

		if entity.tags.CURRENT_PLAYER
			@player = entity
		else
			@opponent = entity

	receiveEntity: (definition, action) ->
		# console.log 'receiving entity', definition.id, definition, @entities[definition.id]
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition, action)
		#if definition.id is 72
			#console.log 'receving entity', definition, entity

	receiveTagChange: (change, action) ->
		# if change.tag is 'RESOURCES_USED'
		# 	console.log '\t\treceiving tag change', change, @entities[change.entity], change.value

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
		# console.log '\t\treceiving show entity', definition.id, definition
		if @entities[definition.id]
			@entities[definition.id].update(definition, action)
		else
			@entities[definition.id] = new Entity(definition, this)

		# Since patch 5.2.0.13619, the first showEntity with a cardID (and that is not an enchantment, cf tavern
		# brawl conditions) always comes from the current player
		# Case of newer replay
		if (@player is null or @opponent is null) and definition.cardID and definition.tags?.CARDTYPE != 6
			entity = @entities[definition.id]
			# console.log 'setting player', entity
			for player in @players
				if player.tags.CONTROLLER is entity.tags.CONTROLLER
					@player = player
					# console.log '\tsetting player', @player
				else 
					@opponent = player
					# console.log '\tsetting opponent', @opponent
			# console.log 'set player and opponent', @player, @opponent

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
			# console.log 'highlighting', @entities[option.entity]
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
		if inputTurnNumber in ['Mulligan', 'mulligan']
			turnNumber = 'mulligan'

		else if inputTurnNumber is 'endgame'
			turnNumber = 'endgame'

		else if @turns[2].activePlayer == @player
			if inputTurnNumber % 2 == 0
				turnNumber = 't' + inputTurnNumber / 2 + 'o'
			else
				turnNumber = 't' + (inputTurnNumber + 1) / 2
		else
			if inputTurnNumber % 2 != 0
				turnNumber = 't' + (inputTurnNumber + 1) / 2 + 'o'
			else
				turnNumber = 't' + inputTurnNumber / 2

		@onTurnChanged? turnNumber

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
		images = []

		ids = []
		# console.log 'building image array', @entities
		# Entities are roughly added in the order of apparition
		for k,v of @entities
			ids.push v.cardID

		for id in ids
			card = @cardUtils.getCard(id)
			# console.log 'preloading', id, card
			if card and card.type != 'Enchantment'
				images.push @cardUtils.buildFullCardImageUrl(card)

		# console.log 'image array', images
		return images

	preloadPictures: (arrayOfImages) ->
		arrayOfImages.forEach (img) ->
			# console.log 'preloading', img
			(new Image()).src = img


module.exports = ReplayPlayer
