Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
HistoryItem = require './history-item'
ActionParser = require './action-parser'
_ = require 'lodash'
EventEmitter = require 'events'

class ReplayPlayer extends EventEmitter
	constructor: (@parser) ->
		EventEmitter.call(this)

		window.replay = this

		@currentTurn = 0
		@currentActionInTurn = 0
		@cardUtils = window['parseCardsText']

	init: ->
		console.log 'starting init'
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

		@parser.parse(this)

		# Trigger the population of all the main game entities
		@initializeGameState()

		# @goToTimestamp @currentReplayTime
		@update()

		# Parse the data to build the game structure
		@actionParser = new ActionParser(this)
		@actionParser.populateEntities()
		@actionParser.parseActions()

		# Adjust who is player / opponent
		if (parseInt(@opponent.id) == parseInt(@mainPlayerId))
			@switchMainPlayer()

		# Notify the UI controller
		@emit 'game-generated', this
		@emit 'players-ready'

		# Preload the images
		images = @buildImagesArray()
		@preloadPictures images

		# @finalizeInit()
		# And go to the fisrt action
		@goNextAction()

	autoPlay: ->
		@speed = @previousSpeed || 1
		if @speed > 0
			@interval = setInterval((=> @goNextAction()), @frequency / @speed)

	pause: ->
		if @speed > 0
			@previousSpeed = @speed
		@speed = 0
		clearInterval(@interval)

	changeSpeed: (speed) ->
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
			# console.log 'goign to next turn'
			@currentTurn++
			@currentActionInTurn = -1

			if !@turns[@currentTurn]
				return

			@emit 'new-turn', @turns[@currentTurn]

			# Sometimes the first action in a turn isn't a card draw, but start-of-turn effects, so we can't easily skip 
			# the draw card action (and also, it makes things a bit clearer when the player doesn't do anything on their turn)
			# targetTimestamp = 1000 * (@turns[@currentTurn].timestamp - @startTimestamp) + 0.0000001

			# @goToTimestamp targetTimestamp
			@goToIndex @turns[@currentTurn].index

	goNextTurn: ->
		if @turns[@currentTurn + 1]
			turnWhenCommandIssued = @currentTurn

			while turnWhenCommandIssued == @currentTurn
				@goNextAction()

	goPreviousAction: ->
		@newStep()

		if @currentActionInTurn == 1
			targetTurn = @currentTurn
			targetAction = 0

		# Go to Mulligan
		else if @currentActionInTurn <= 0 and @currentTurn <= 2
			targetTurn = 0
			targetAction = 0

		else if @currentActionInTurn <= 0
			# console.log 'targeting end of previous turn. Previous turn is', @turns[@currentTurn - 1]
			targetTurn = @currentTurn - 1
			targetAction = @turns[targetTurn].actions.length - 1

		else
			targetTurn = @currentTurn
			targetAction = @currentActionInTurn - 1

		@currentTurn = 0
		@currentActionInTurn = -1
		@init()

		# Mulligan
		if targetTurn == 0 and targetAction == 0
			return

		while @currentTurn != targetTurn or @currentActionInTurn != targetAction
			@goNextAction()

	goPreviousTurn: ->
		@newStep()

		targetTurn = Math.max(1, @currentTurn - 1)

		@currentTurn = 0
		@currentActionInTurn = 0
		@init()

		while @currentTurn != targetTurn
			@goNextAction()

	goToAction: ->
		# @newStep()

		if @currentActionInTurn >= 0
			console.log 'going to action', @currentActionInTurn, @turns[@currentTurn].actions
			action = @turns[@currentTurn].actions[@currentActionInTurn]
			@updateActiveSpell action
			@emit 'new-action', action

			if action.target
				@targetSource = action?.data.id
				@targetDestination = action.target
				@targetType = action.actionType

			# Now we want to go to the action, and to show the effects of the action - ie all 
			# that happens until the next action. Otherwise the consequence of an action would 
			# be bundled with the next action, which is less intuitive
			if @turns[@currentTurn].actions[@currentActionInTurn + 1] 
				index = @turns[@currentTurn].actions[@currentActionInTurn + 1].index - 1
			else if @turns[@currentTurn + 1]
				index = @turns[@currentTurn + 1].index - 1
			else
				index = @history[@history.length - 1].index

			# targetTimestamp = 1000 * (action.timestamp - @startTimestamp) + 0.0000001
			# @goToTimestamp targetTimestamp
			@goToIndex index

	goToTurn: (turn) ->
		# @newStep()
		targetTurn = parseInt(turn)
		console.log 'going to turn', targetTurn
		# targetTurn = turn + 1

		@currentTurn = 0
		@currentActionInTurn = 0
		@init()

		while @currentTurn != targetTurn
			console.log '\tand going to next action', @currentTurn, targetTurn, @currentActionInTurn
			@goNextAction()

	goToIndex: (index) ->
		if index < @historyPosition
			@historyPosition = 0
			@init()

		@targetIndex = index
		@update()

		@emit 'moved-timestamp'

	# goToTimestamp: (timestamp) ->
	# 	if timestamp < @currentReplayTime
	# 		@historyPosition = 0
	# 		@init()

	# 	@currentReplayTime = timestamp
	# 	@update()

	# 	@emit 'moved-timestamp'

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
		console.log 'moving to timestamp', timestamp
		@newStep()

		lastTimestamp = 0
		index = 0
		while !lastTimestamp or (lastTimestamp < timestamp)
			lastTimestamp = @history[++index].timestamp

		itemIndex = @history[index].index
		console.log 'going to itemIndex', itemIndex

		targetTurn = -1
		targetAction = -1

		for i in [1..@turns.length]
			turn = @turns[i]
			console.log 'looking at turn', turn, turn.actions[1]
			# If the turn starts after the timestamp, this means that the action corresponding to the timestamp started in the previous turn
			if turn.index > itemIndex
				console.log 'breaking on turn', i, turn
				break
			# If the turn has no timestamp, try to default to the first action's timestamp
			if !turn.index > itemIndex and turn.actions?.length > 0 and turn.actions[0].index > itemIndex
				break
			targetTurn = i

			if turn.actions.length > 0
				targetAction = -1
				for j in [0..turn.actions.length - 1]
					action = turn.actions[j]
					console.log '\tlooking at action', action
					if !action or !action.index or action?.index > itemIndex
						break
						# Action -1 matches the beginning of the turn
					targetAction = j - 1


		# TODO: reset only if move backwards
		@currentTurn = 0
		@currentActionInTurn = 0
		@historyPosition = 0
		@init()

		console.log 'moveToTimestamp init done', targetTurn, targetAction

		# Mulligan
		if targetTurn <= 1 or targetAction < -1
			return

		while @currentTurn != targetTurn or @currentActionInTurn != targetAction
			@goNextAction()


	getActivePlayer: ->
		return @turns[@currentTurn]?.activePlayer || {}

	newStep: ->
		@targetSource = undefined
		@targetDestination = undefined
		@discoverAction = undefined
		@previousActiveSpell = @activeSpell
		@activeSpell = undefined
		console.log 'new step', @activeSpell, @previousActiveSpell
		for k,v of @entities
			v.damageTaken = v.tags.DAMAGE or 0
			v.highlighted = false

	getTotalLength: ->
		timestamp = null
		i = 1
		while !timestamp
			timestamp = @history[@history.length - i++].timestamp
		return timestamp - @startTimestamp

	getElapsed: ->
		# console.log 'elapsed', @currentReplayTime
		@currentReplayTime

	getTimestamps: ->
		return _.map @history, (batch) => batch.timestamp - @startTimestamp

	

	

	update: ->
		#@currentReplayTime += @frequency * @speed
		# if (@currentReplayTime >= @getTotalLength() * 1000)
		# 	@currentReplayTime = @getTotalLength() * 1000

		# elapsed = @getElapsed()
		# console.log 'elapsed', elapsed
		while @history[@historyPosition] and @history[@historyPosition].index <= @targetIndex
			# console.log '\tprocessing', @historyPosition, @targetIndex, @history[@historyPosition]
			@history[@historyPosition++].execute(this)
			# if elapsed > @history[@historyPosition].timestamp - @startTimestamp
			# 	# console.log '\tprocessing', elapsed, @history[@historyPosition].timestamp - @startTimestamp, @history[@historyPosition].timestamp, @startTimestamp, @history[@historyPosition]
			# 	@history[@historyPosition].execute(this)
			# 	@historyPosition++
			# else

		@updateOptions()
		if @history[@historyPosition - 1]?.timestamp
			@currentReplayTime = @history[@historyPosition - 1].timestamp - @startTimestamp
			console.log '\tupdating timestamp', @currentReplayTime

	updateOptions: ->
		if @getActivePlayer() == @player
			# console.log 'updating options', @history.length, @historyPosition
			currentCursor = @historyPosition
			while currentCursor < @history.length
				if @history[currentCursor].command is 'receiveOptions'
					# console.log 'updating options?', command
					@history[currentCursor].execute(this)
					return
				currentCursor++
		#console.log 'stopped at history', @history[@historyPosition].timestamp, elapsed

	updateActiveSpell: (action) ->
		realAction = action.mainAction?.associatedAction || action
		mainEntity = action.mainAction?.associatedAction?.data || action.data
		if mainEntity?.tags?.CARDTYPE is 5 and realAction.actionType is 'played-card-from-hand'
			console.log '\tupdating active spell', mainEntity
			@activeSpell = mainEntity
		else if realAction.actionType in ['minion-death', 'secret-revealed', 'card-draw']
			console.log '\tstill showing previous spell', @activeSpell, @previousActiveSpell
			@activeSpell = @previousActiveSpell
			@previousActiveSpell = undefined

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
		if @player.tags.CONTROLLER == controllerId
			return @player
		return @opponent


	# ==================
	# Initialization
	# ==================
	initializeGameState: ->
		# Find the index of the last FullEntity creation
		index = 0
		while @history[index].command isnt 'receiveAction'
			index++
		index++
		while @history[index].command isnt 'receiveAction'
			index++
		console.log 'last index before action', index, @history[index], @history[index + 1]
		@goToIndex @history[index].index


	# ==================
	# Processing the different state changes
	# ==================
	receiveGameEntity: (definition) ->
		# console.log 'receiving game entity', definition
		entity = new Entity(this)
		@game = @entities[definition.id] = entity
		entity.update(definition)

	receivePlayer: (definition) ->
		# console.log 'receiving player', definition
		entity = new Player(this)
		@entities[definition.id] = entity
		@players.push(entity)
		entity.update(definition)

		if entity.tags.CURRENT_PLAYER
			@player = entity
		else
			@opponent = entity

	receiveEntity: (definition) ->
		# console.log 'receiving entity', definition.id, definition
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition)
		#if definition.id is 72
			#console.log 'receving entity', definition, entity

	receiveTagChange: (change) ->
		# console.log 'receiving tag change', change
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
		# console.log 'receiving show entity', definition
		if @entities[definition.id]
			@entities[definition.id].update(definition)
		else
			@entities[definition.id] = new Entity(definition, this)

	receiveAction: (definition) ->
		# console.log 'receiving action', definition
		if definition.isDiscover
			@discoverAction = definition
			@discoverController = @getController(@entities[definition.attributes.entity].tags.CONTROLLER)

	receiveOptions: (options) ->
		# console.log 'receiving options', options

		for k,v of @entities
			v.highlighted = false

		for option in options.options
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
		console.log 'getting player info', @opponent, @entities[@opponent.tags.HERO_ENTITY], @getClass(@entities[@opponent.tags.HERO_ENTITY].cardID)
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
		
		# console.log 'preloaded images'	

	# Replace the tN keywords
	replaceKeywordsWithTimestamp: (text) ->
		turnRegex = /(\s|^)(t|T)\d?\d(:|\s|,|\.|\?)/gm
		opoonentTurnRegex = /(\s|^)(t|T)\d?\do(:|\s|,|\.|\?)/gm

		longTurnRegex = /(\s|^)(turn|Turn)\s?\d?\d(:|\s|,|\.|\?)/gm
		longOpponentTurnRegex = /(\s|^)(turn|Turn)\s?\d?\do(:|\s|,|\.|\?)/gm

		mulliganRegex = /(\s|^)(m|M)ulligan(:|\s|\?)/gm

		that = this

		matches = text.match(turnRegex)
		if matches and matches.length > 0
			matches.forEach (match) ->
				match = match.trimLeft()
				# console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring 1, match.length - 1)
				text = that.replaceText text, inputTurnNumber, match
				

		matches = text.match(opoonentTurnRegex)
		if matches and matches.length > 0
			matches.forEach (match) ->
				match = match.trimLeft()
				#console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring 1, match.length - 1)
				text = that.replaceText text, inputTurnNumber, match, true
		
		matches = text.match(longTurnRegex)
		if matches and matches.length > 0
			matches.forEach (match) ->
				match = match.trimLeft()
				# console.log '\tmatch', match, match.substring(4, match.length - 1)
				inputTurnNumber = parseInt(match.substring(4, match.length - 1).trim())
				text = that.replaceText text, inputTurnNumber, match

		matches = text.match(longOpponentTurnRegex)
		if matches and matches.length > 0
			matches.forEach (match) ->
				match = match.trimLeft()
				#console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring(4, match.length - 1).trim())
				text = that.replaceText text, inputTurnNumber, match, true

		matches = text.match(mulliganRegex)
		if matches and matches.length > 0
			matches.forEach (match) ->
				text = text.replace match, '<a ng-click="goToTimestamp(\'1\')" class="ng-scope">' + match + '</a>'

		#console.log 'modified text', text
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
		text = text.replace match, '<a ng-click="goToTimestamp(\'' + turnNumber + '\')" class="ng-scope">' + match + '</a>'
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
