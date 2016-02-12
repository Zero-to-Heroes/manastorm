Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
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
		@entities = {}
		@players = []
		@emit 'reset'

		@game = null
		@player = null
		@opponent = null

		@history = []
		@historyPosition = 0
		@lastBatch = null

		@frequency = 2000
		@currentReplayTime = 200

		@started = false
		@speed = 0

		@turns = {
			length: 0
		}

		@buildCardLink = @cardUtils.buildCardLink

		@parser.parse(this)

		# Trigger the population of all the main game entities
		@goToTimestamp @currentReplayTime
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
		else if @turns[@currentTurn].activePlayer == @player
			return 'Turn ' + Math.ceil(@turns[@currentTurn].turn / 2)
		else
			return 'Turn ' + Math.ceil(@turns[@currentTurn].turn / 2) + 'o'


	# ========================
	# Moving inside the replay (with player controls)
	# ========================
	goNextAction: ->
		console.log 'clicked goNextAction', @currentTurn, @currentActionInTurn
		@newStep()
		@currentActionInTurn++

		console.log 'goNextAction', @turns[@currentTurn], @currentActionInTurn, if @turns[@currentTurn] then @turns[@currentTurn].actions
		# Navigating within the same turn
		if (@turns[@currentTurn] && @currentActionInTurn <= @turns[@currentTurn].actions.length - 1) 
			@goToAction()

		# Going to the next turn
		else if @turns[@currentTurn + 1]
			console.log 'goign to next turn'
			@currentTurn++
			@currentActionInTurn = -1

			if !@turns[@currentTurn]
				return

			@emit 'new-turn', @turns[@currentTurn]

			# Sometimes the first action in a turn isn't a card draw, but start-of-turn effects, so we can't easily skip 
			# the draw card action (and also, it makes things a bit clearer when the player doesn't do anything on their turn)
			targetTimestamp = 1000 * (@turns[@currentTurn].timestamp - @startTimestamp) + 1

			@goToTimestamp targetTimestamp

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
		@newStep()

		if @currentActionInTurn >= 0
			console.log 'going to action', @currentActionInTurn, @turns[@currentTurn].actions
			action = @turns[@currentTurn].actions[@currentActionInTurn]
			@emit 'new-action', action
			targetTimestamp = 1000 * (action.timestamp - @startTimestamp) + 1

			if action.target
				target = @entities[action.target]
				@targetSource = action?.data.id
				@targetDestination = target.id
				@targetType = action.actionType

			@goToTimestamp targetTimestamp

	goToTurn: (turn) ->
		@newStep()

		targetTurn = turn + 1

		@currentTurn = 0
		@currentActionInTurn = 0
		@init()

		while @currentTurn != targetTurn
			@goNextAction()

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
		targetTurn = -1
		targetAction = -1

		for i in [1..@turns.length]
			turn = @turns[i]
			console.log 'looking at timestamp', turn.timestamp, turn, turn.actions[1]
			# If the turn starts after the timestamp, this means that the action corresponding to the timestamp started in the previous turn
			if turn.timestamp > timestamp
				console.log 'breaking on turn', i, turn
				break
			# If the turn has no timestamp, try to default to the first action's timestamp
			if !turn.timestamp > timestamp and turn.actions?.length > 0 and turn.actions[0].timestamp > timestamp
				break
			targetTurn = i

			if turn.actions.length > 0
				targetAction = -1
				for j in [0..turn.actions.length - 1]
					action = turn.actions[j]
					console.log '\tlooking at action', action
					if !action or !action.timestamp or action?.timestamp > timestamp
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
		

	goToTimestamp: (timestamp) ->
		if timestamp < @currentReplayTime
			console.log 'going back in time, resetting', timestamp, @currentReplayTime
			@emit 'reset'
			@historyPosition = 0
			@init()

		@currentReplayTime = timestamp
		@update()

		@emit 'moved-timestamp'


	getActivePlayer: ->
		return @turns[@currentTurn]?.activePlayer || {}

	newStep: ->
		@targetSource = undefined
		@targetDestination = undefined
		@discoverAction = undefined

	getTotalLength: ->
		return @history[@history.length - 1].timestamp - @startTimestamp

	getElapsed: ->
		@currentReplayTime / 1000

	getTimestamps: ->
		return _.map @history, (batch) => batch.timestamp - @startTimestamp

	

	# Replace the tN keywords
	replaceKeywordsWithTimestamp: (text) ->
		turnRegex = /(t|T)\d?\d(:|\s|,|\.)/gm
		opoonentTurnRegex = /(t|T)\d?\do(:|\s|,|\.)/gm
		mulliganRegex = /(m|M)ulligan(:|\s)/gm
		roundRegex = /(r|R)\d?\d(:|\s|,|\.)/gm

		that = this
		matches = text.match(turnRegex)

		if matches and matches.length > 0
			matches.forEach (match) ->
				#console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring 1, match.length - 1)
				#console.log '\tinputTurnNumber', inputTurnNumber
				# Now compute the "real" turn. This depends on whether you're the first player or not
				if that.turns[2].activePlayer == that.player
					turnNumber = inputTurnNumber * 2
				else
					turnNumber = inputTurnNumber * 2 + 1
				turn = that.turns[turnNumber]
				#console.log '\tturn', turn
				if turn
					timestamp = turn.timestamp + 1
					#console.log '\ttimestamp', (timestamp - that.startTimestamp)
					formattedTimeStamp = that.formatTimeStamp (timestamp - that.startTimestamp)
					#console.log '\tformattedTimeStamp', formattedTimeStamp
					text = text.replace match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>'

		matches = text.match(opoonentTurnRegex)

		if matches and matches.length > 0
			matches.forEach (match) ->
				#console.log '\tmatch', match
				inputTurnNumber = parseInt(match.substring 1, match.length - 1)
				#console.log '\tinputTurnNumber', inputTurnNumber
				# Now compute the "real" turn. This depends on whether you're the first player or not
				if that.turns[2].activePlayer == that.opponent
					turnNumber = inputTurnNumber * 2
				else
					turnNumber = inputTurnNumber * 2 + 1
				turn = that.turns[turnNumber]
				#console.log '\tturn', turn
				if turn
					timestamp = turn.timestamp + 1
					#console.log '\ttimestamp', (timestamp - that.startTimestamp)
					formattedTimeStamp = that.formatTimeStamp (timestamp - that.startTimestamp)
					#console.log '\tformattedTimeStamp', formattedTimeStamp
					text = text.replace match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>'

		matches = text.match(mulliganRegex)

		if matches and matches.length > 0
			matches.forEach (match) ->
				turn = that.turns[1]
				timestamp = turn.timestamp
				#console.log 'timestamp', timestamp, that.startTimestamp
				formattedTimeStamp = that.formatTimeStamp (timestamp - that.startTimestamp)
				#console.log 'formatted time stamp', formattedTimeStamp
				text = text.replace match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>'

		#console.log 'modified text', text
		return text

	formatTimeStamp: (length) ->
		totalSeconds = "" + Math.floor(length % 60)
		if totalSeconds.length < 2
			totalSeconds = "0" + totalSeconds
		totalMinutes = Math.floor(length / 60)
		if totalMinutes.length < 2
			totalMinutes = "0" + totalMinutes

		return totalMinutes + ':' + totalSeconds

	update: ->
		#@currentReplayTime += @frequency * @speed
		if (@currentReplayTime >= @getTotalLength() * 1000)
			@currentReplayTime = @getTotalLength() * 1000

		elapsed = @getElapsed()
		while @historyPosition < @history.length
			if elapsed > @history[@historyPosition].timestamp - @startTimestamp
				#console.log 'processing', @history[@historyPosition]
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

	switchMainPlayer: ->
		tempOpponent = @player
		@player = @opponent
		@opponent = tempOpponent
		@mainPlayerId = @player.id
		console.log 'switched main player, new one is', @mainPlayerId, @player

	getController: (controllerId) ->
		if @player.tags.CONTROLLER == controllerId
			return @player
		return @opponent

	receiveEntity: (definition) ->
		#console.log 'receiving entity', definition.id, definition
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition)
		#if definition.id is 72
			#console.log 'receving entity', definition, entity

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
		# console.log 'receiving action', definition
		if definition.isDiscover
			@discoverAction = definition
			@discoverController = @getController(@entities[definition.attributes.entity].tags.CONTROLLER)

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

	forceReemit: ->
		@emit 'new-turn', @turns[@currentTurn]

	notifyNewLog: (log) ->
		@emit 'new-log', log

	getPlayerInfo: ->
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

module.exports = ReplayPlayer
