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

		window.replay = this

		@currentTurn = 0
		@currentActionInTurn = 0
		@cardUtils = window['parseCardsText']

	reload: (xmlReplay) ->
		@parser.xmlReplay = xmlReplay
		# EventEmitter.call(this)
		# console.log 'init parser', @parser, xmlReplay
		@init()


	init: ->
		# console.log 'starting init in joustjs'
		if @entities
			for k,v of @entities
				v.damageTaken = 0
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
		@emit 'players-ready'

		# Preload the images
		images = @buildImagesArray()
		@preloadPictures images
		# console.log 'preloadPictures done'

		# @finalizeInit()
		# And go to the fisrt action
		@goNextAction()
		# console.log 'init done in joustjs', @turns

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
		else if @getActivePlayer() == @player
			return 'Turn ' + Math.ceil(@turns[@currentTurn].turn / 2)
		else
			return 'Turn ' + Math.ceil(@turns[@currentTurn].turn / 2) + 'o'



	# ========================
	# Moving inside the replay (with player controls)
	# ========================
	goNextAction: ->
		# console.log 'clicked goNextAction', @currentTurn, @currentActionInTurn
		@newStep()
		@currentActionInTurn++

		# console.log 'goNextAction', @turns[@currentTurn], @currentActionInTurn, if @turns[@currentTurn] then @turns[@currentTurn].actions
		# Navigating within the same turn
		if (@turns[@currentTurn] && @currentActionInTurn <= @turns[@currentTurn].actions.length - 1) 
			@goToAction()

		# Going to the next turn
		else if @turns[@currentTurn + 1]
			# console.log 'goign to next turn', @currentTurn + 1
			@currentTurn++
			@currentActionInTurn = -1

			if !@turns[@currentTurn]
				return

			@emit 'new-turn', @turns[@currentTurn]

			@goToIndex @turns[@currentTurn].index

	goNextTurn: ->
		# console.log 'going to next turn', @currentTurn + 1
		if @turns[@currentTurn + 1]
			turnWhenCommandIssued = @currentTurn

			while turnWhenCommandIssued == @currentTurn
				@goNextAction()

	goPreviousAction: (lastIteration) ->
		# console.log 'going to previous action', @currentTurn, @currentActionInTurn
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
			# @emit 'previous-action', rollbackAction

		else
			targetTurn = @currentTurn
			targetAction = @currentActionInTurn - 1


		if rollbackAction.shouldExecute and !rollbackAction.shouldExecute() and !changeTurn
			# console.log 'skipping back', rollbackAction, @currentTurn, @currentActionInTurn
			@currentActionInTurn = targetAction
			@currentTurn = targetTurn
			# @emit 'previous-action', rollbackAction
			@goPreviousAction lastIteration
		
		else
			# console.log 'rolling back action', @turns, @currentTurn, @currentActionInTurn, rollbackAction
			@rollbackAction rollbackAction
			@emit 'previous-action', rollbackAction

			# previousAction = @turns[targetTurn].actions[targetAction]
			# @updateActiveSpell previousAction

			@currentActionInTurn = targetAction
			@currentTurn = targetTurn

			if !lastIteration
				@goPreviousAction true

			# hack to handle better all targeting, active spell and so on
			# ultimately all the info should be contained in the action itself and we only read from it
			if lastIteration
				@goNextAction()


	goPreviousTurn: ->
		# console.log 'going to previous turn'
		if @turns[@currentTurn - 1]
			# console.log 'previous turn exists'
			turnWhenCommandIssued = @currentTurn

			while @currentTurn >= turnWhenCommandIssued - 1
				# console.log 'going to previous action', @currentTurn, turnWhenCommandIssued
				@goPreviousAction()

			@goNextAction()

		else
			@currentTurn = 0
			@currentActionInTurn = 0
			@init()
			return

		# console.log 'going to previous turn'
		# @newStep()

		# targetTurn = Math.max(1, @currentTurn - 1)

		# @currentTurn = 0
		# @currentActionInTurn = 0
		# @init()

		# while @currentTurn != targetTurn
		# 	@goNextAction()

	goToAction: ->
		# console.log 'going to action', @currentActionInTurn
		if @currentActionInTurn >= 0
			# console.log 'going to action', @currentActionInTurn, @turns[@currentTurn].actions
			action = @turns[@currentTurn].actions[@currentActionInTurn]
			# There are some actions that we can't filter out at construction time (like a minion being returned in hand with Sap)

			if action.shouldExecute and !action.shouldExecute() 
				if !@seeking
					# console.log 'skipping action'
					@goNextAction()

			else
				@updateActiveSpell action
				@emit 'new-action', action

				if action.target
					@targetSource = action?.data.id
					@targetDestination = action.target
					# console.log 'setting target destination', @targetDestination, action
					@targetType = action.actionType

				# Now we want to go to the action, and to show the effects of the action - ie all 
				# that happens until the next action. Otherwise the consequence of an action would 
				# be bundled with the next action, which is less intuitive
				nextActionIndex = 1
				nextAction = @turns[@currentTurn].actions[@currentActionInTurn + nextActionIndex] 
				while nextAction and (nextAction.shouldExecute and !nextAction.shouldExecute())
					nextAction = @turns[@currentTurn].actions[@currentActionInTurn + ++nextActionIndex] 

				if nextAction
					index = nextAction.index - 1
				else if @turns[@currentTurn + 1]
					index = @turns[@currentTurn + 1].index - 1
				else
					index = @history[@history.length - 1].index

				@goToIndex index

	goToTurn: (turn) ->
		targetTurn = parseInt(turn)
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

		# @currentTurn = 0
		# @currentActionInTurn = 0
		# @init()


		# while @currentTurn != targetTurn
		# 	# console.log '\tand going to next action', @currentTurn, targetTurn, @currentActionInTurn
		# 	@goNextAction()

	goToIndex: (index) ->
		# console.log 'going to index', index
		if index < @historyPosition
			@historyPosition = 0
			@init()

		@targetIndex = index
		@update()

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
		# console.log 'moving to timestamp', timestamp
		@newStep()

		# lastTimestamp = 0
		# index = 0
		# while !lastTimestamp or (lastTimestamp < timestamp)
		# 	lastTimestamp = @history[++index].timestamp

		# Going forward
		@seeking = true
		# console.log 'moving on the timeline', timestamp, @getCurrentTimestamp()
		if timestamp > @getCurrentTimestamp()
			# console.log '\tforward'
			while !@getCurrentTimestamp() or timestamp > @getCurrentTimestamp()
				@goNextAction()
		else if timestamp < @getCurrentTimestamp()
			# console.log '\tbackward'
			while !@getCurrentTimestamp() or timestamp < @getCurrentTimestamp()
				@goPreviousAction()
		@seeking = false


	getCurrentTimestamp: ->
		if !@turns[@currentTurn].actions[@currentActionInTurn] or !@turns[@currentTurn].actions[@currentActionInTurn].timestamp
			timestamp = @turns[@currentTurn].timestamp
			index = Math.max @currentActionInTurn, 0
			while !timestamp and index < 200 # preventing infinite loops
				timestamp = @turns[@currentTurn].actions[index++]?.timestamp
		else
			timestamp = @turns[@currentTurn].actions[@currentActionInTurn].timestamp
		# console.log '\t\tgetting current timestamp', timestamp
		# if !timestamp
		# 	console.warn '\t\tcould not get timestamp', @turns[@currentTurn], @currentTurn, @currentActionInTurn, @turns, index
		return timestamp


		# if timestamp >= lastTimestamp
		# 	@goToIndex @history[@history.length - 1].index
		# 	return



		# itemIndex = @history[index].index
		# # console.log 'going to itemIndex', itemIndex

		# targetTurn = -1
		# targetAction = -1

		# for i in [1..@turns.length]
		# 	turn = @turns[i]
		# 	# console.log 'looking at turn', turn, turn.actions[1]
		# 	# If the turn starts after the timestamp, this means that the action corresponding to the timestamp started in the previous turn
		# 	if turn.index > itemIndex
		# 		# console.log 'breaking on turn', i, turn
		# 		break
		# 	# If the turn has no timestamp, try to default to the first action's timestamp
		# 	if !turn.index > itemIndex and turn.actions?.length > 0 and turn.actions[0].index > itemIndex
		# 		break
		# 	targetTurn = i

		# 	if turn.actions.length > 0
		# 		targetAction = -1
		# 		for j in [0..turn.actions.length - 1]
		# 			action = turn.actions[j]
		# 			# console.log '\tlooking at action', action
		# 			if !action or !action.index or action?.index > itemIndex
		# 				break
		# 				# Action -1 matches the beginning of the turn
		# 			targetAction = j - 1


		# # TODO: reset only if move backwards
		# @currentTurn = 0
		# @currentActionInTurn = 0
		# @historyPosition = 0
		# @init()

		# console.log 'moveToTimestamp init done', targetTurn, targetAction

		# # Mulligan
		# if targetTurn <= 1 or targetAction < -1
		# 	return

		# @seeking = true
		# # console.log 'going to timestamp, targets', targetTurn, targetAction
		# while @currentTurn != targetTurn or @currentActionInTurn != targetAction
		# 	# console.log '\tmoving to next action', @currentTurn, @currentActionInTurn, targetAction

		# 	# Avoid double clicking on skipped actions
		# 	action = @turns[@currentTurn].actions[@currentActionInTurn + 1]
		# 	if @currentTurn == targetTurn and @currentActionInTurn == targetAction - 1 and action?.shouldExecute and !action?.shouldExecute() 
		# 		break

		# 	@goNextAction()

		# @seeking = false


	getActivePlayer: ->
		return @turns[@currentTurn]?.activePlayer || {}

	newStep: ->
		@targetSource = undefined
		@targetDestination = undefined
		@discoverAction = undefined
		@previousActiveSpell = @activeSpell
		@activeSpell = undefined
		# console.log 'new step', @activeSpell, @previousActiveSpell
		for k,v of @entities
			v.damageTaken = v.tags.DAMAGE or 0
			v.highlighted = false

	getTotalLength: ->
		timestamp = null
		i = 1
		while !timestamp and @history.length - i > 0
			timestamp = @history[@history.length - i++]?.timestamp
		if timestamp
			return timestamp - @startTimestamp
		return null

	getElapsed: ->
		# console.log 'elapsed', @currentReplayTime
		@currentReplayTime

	getTimestamps: ->
		return _.map @history, (batch) => batch.timestamp - @startTimestamp


	update: ->
		# console.log 'moving to index', @targetIndex, @historyPosition, @history[@historyPosition]
		while @history[@historyPosition] and @history[@historyPosition].index <= @targetIndex
			# console.log '\tgo'
			# if !@history[@historyPosition].executed
			# console.log '\tprocessing', @historyPosition, @targetIndex, @history[@historyPosition], @history[@historyPosition + 1]
			# console.log '\t\tturns', @turns[@currentTurn], @currentTurn, @turns
			if @turns[@currentTurn]
				action = @turns[@currentTurn].actions[@currentActionInTurn]

			@history[@historyPosition].execute(this, action)
			@historyPosition++
			# console.log '\t\tprocessed'


		@updateOptions()
		if @history[@historyPosition - 1]?.timestamp
			@currentReplayTime = @history[@historyPosition - 1].timestamp - @startTimestamp
			# console.log '\tupdating timestamp', @currentReplayTime

		# console.log 'update finished'

	rollbackAction: (action) ->
		# console.log 'going backwards', action
		while @history[@historyPosition] and @history[@historyPosition].index > action.index
			@historyPosition--

		for k, v of action.rollbackInfo
			# console.log '\tupdating entity', k, v, @entities[k], action
			@entities[k].update tags: v

		@updateOptions()
		if @history[@historyPosition - 1]?.timestamp
			@currentReplayTime = @history[@historyPosition - 1].timestamp - @startTimestamp
			# console.log '\tupdating timestamp', @currentReplayTime

	# addBackInTimeInfo: (action, historyElement) ->
	# 	# Will be an object containing, for each entity whose tag has changed, and the initial value of that tag at the beginning 
	# 	# of the action
	# 	action.backInfo = action.backInfo || {}
	# 	historyElement.executeBackInTime(this, action)

	choosing: ->
		# Blur during mulligan
		if @turns[@currentTurn].turn is 'Mulligan'
			return true
		# Same for discover
		if @discoverAction
			return true

		return false

	updateOptions: ->
		# console.log 'updating options'
		# Use current action and check if there is no parent? IE allow options only when top-level action has resolved?
		if !@history[@historyPosition]?.parent and @getActivePlayer() == @player
			# console.log 'updating options', @history.length, @historyPosition
			currentCursor = @historyPosition
			while currentCursor > 0
				if @history[currentCursor]?.command is 'receiveOptions'
					# console.log 'updating options?', @history[currentCursor], @history, currentCursor
					@history[currentCursor].execute(this)
					return
				currentCursor--
		# console.log 'stopped at history', @history[@historyPosition].timestamp

	updateActiveSpell: (action) ->
		if !action
			return

		realAction = action.mainAction?.associatedAction || action
		mainEntity = action.mainAction?.associatedAction?.data || action.data
		# console.log 'updating active spell', action, realAction, mainEntity
		if mainEntity?.tags?.CARDTYPE is 5 and realAction.actionType is 'played-card-from-hand'
			# console.log '\tupdating active spell', mainEntity
			@activeSpell = mainEntity
		else if realAction.actionType in ['minion-death', 'secret-revealed', 'card-draw']
			# console.log '\tstill showing previous spell', @activeSpell, @previousActiveSpell
			@activeSpell = @previousActiveSpell
			@previousActiveSpell = undefined

		# @activeSpell = @activeSpell || action.activeSpell

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
		# console.log 'receiving entity', definition.id, definition
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition, action)
		#if definition.id is 72
			#console.log 'receving entity', definition, entity

	receiveTagChange: (change, action) ->
		# if change.tag is 'MULLIGAN_STATE'
		# console.log '\t\treceiving tag change', change, @entities[change.entity]

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
		if definition.isDiscover
			@discoverAction = definition
			@discoverController = @getController(@entities[definition.attributes.entity].tags.CONTROLLER)
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


		# if not timestamp and @lastBatch
		# 	@lastBatch.addCommand([command, args])
		# else
		# 	@lastBatch = new HistoryBatch(timestamp, [command, args])
		# 	@history.push(@lastBatch)
		# return @lastBatch



	# ==================
	# Communication with other entities
	# ==================
	forceReemit: ->
		@emit 'new-turn', @turns[@currentTurn]

	notifyNewLog: (log) ->
		@emit 'new-log', log

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
		turnRegex = /(\s|^)(t|T)\d?\d(:|\s|,|\.|\?)/gm
		opoonentTurnRegex = /(\s|^)(t|T)\d?\do(:|\s|,|\.|\?)/gm

		longTurnRegex = /(\s|^)(turn|Turn)\s?\d?\d(:|\s|,|\.|\?)/gm
		longOpponentTurnRegex = /(\s|^)(turn|Turn)\s?\d?\do(:|\s|,|\.|\?)/gm

		mulliganRegex = /(\s|^)(m|M)ulligan(:|\s|\?)/gm

		that = this

		matches = text.match(turnRegex)
		if matches and matches.length > 0
			matches = _.uniq matches
			matches.forEach (match) ->
				# console.log 'matching own turn', match
				match = match.trimLeft()
				inputTurnNumber = parseInt(match.substring 1, match.length - 1)
				text = that.replaceText text, inputTurnNumber, match
				

		matches = text.match(opoonentTurnRegex)
		if matches and matches.length > 0
			matches = _.uniq matches
			matches.forEach (match) ->
				match = match.trimLeft()
				#console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring 1, match.length - 1)
				text = that.replaceText text, inputTurnNumber, match, true
		
		matches = text.match(longTurnRegex)
		# console.log 'looking for match', text, matches
		if matches and matches.length > 0
			matches = _.uniq matches
			matches.forEach (match) ->
				match = match.trimLeft()
				# console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring(4, match.length - 1).trim())
				# console.log '\tinputTurnNumber', inputTurnNumber
				text = that.replaceText text, inputTurnNumber, match
				# console.log '\tupdated', text

		matches = text.match(longOpponentTurnRegex)
		if matches and matches.length > 0
			matches = _.uniq matches
			matches.forEach (match) ->
				match = match.trimLeft()
				#console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring(4, match.length - 1).trim())
				text = that.replaceText text, inputTurnNumber, match, true

		matches = text.match(mulliganRegex)
		if matches and matches.length > 0
			matches = _.uniq matches
			matches.forEach (match) ->
				text = text.replace match, '<a ng-click="mediaPlayer.goToTimestamp(\'1\')" class="ng-scope">' + match + '</a>'

		# console.log 'modified text', text
		return text

	replaceText: (text, inputTurnNumber, match, opponent) ->

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
			return text
			
		match = match.replace '?', ''
		match = match.trim()
		match = match.replace ':', ''
		match = match.replace ',', ''
		match = match.replace '.', ''
		# console.log 'replacing match', match
		text = text.replace new RegExp('\\b' + match + '\\b', 'g'), '<a ng-click="mediaPlayer.goToTimestamp(\'' + turnNumber + '\')" class="ng-scope">' + match + '</a>'
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
			# console.log 'adding entity', k, v
			ids.push v.cardID

		for id in ids
			images.push @cardUtils.buildFullCardImageUrl(@cardUtils.getCard(id))

		# console.log 'image array', images
		return images

	preloadPictures: (arrayOfImages) ->
		arrayOfImages.forEach (img) ->
			# console.log 'preloading', img
			(new Image()).src = img


module.exports = ReplayPlayer
