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

		# else
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

	# finalizeInit: ->

	# 	@goToTimestamp @currentReplayTime
	# 	@update()

	# 	players = [@player, @opponent]
	# 	#@speed = 0

	# 	#First add the missing card / entity info
	# 	playerIndex = 0
	# 	turnNumber = 1
	# 	actionIndex = 0
	# 	currentPlayer = players[playerIndex]
	# 	#populate the entities
	# 	for batch, i in @history
	# 		for command, j in batch.commands
	# 			## Populate relevant data for cards
	# 			if (command[0] == 'receiveShowEntity')
	# 				if (command[1].length > 0 && command[1][0].id && @entities[command[1][0].id]) 
	# 					@entities[command[1][0].id].cardID = command[1][0].cardID
	# 			if (command[0] == 'receiveEntity')
	# 				if (command[1].length > 0 && command[1][0].id && !@entities[command[1][0].id]) 
	# 					entity = new Entity(this)
	# 					definition = _.cloneDeep command[1][0]
	# 					@entities[definition.id] = entity
	# 					# Entity not in the game yet
	# 					definition.tags.ZONE = 6
	# 					entity.update(definition)


	# 	# Add intrinsic information, like whether the card is a secret
	# 	for batch, i in @history
	# 		for command, j in batch.commands
	# 			if command[0] == 'receiveTagChange'
	# 				# Adding information that this entity is a secret
	# 				if command[1][0].tag == 'SECRET' and command[1][0].value == 1
	# 					@entities[command[1][0].entity].tags[command[1][0].tag] = command[1][0].value
	# 			if command[0] == 'receiveShowEntity'
	# 				if command[1][0].tags.SECRET == 1
	# 					@entities[command[1][0].id].tags.SECRET = 1

	# 	# Build the list of turns along with the history position of each
	# 	playerIndex = 0
	# 	turnNumber = 1
	# 	currentPlayer = players[playerIndex]
	# 	for batch, i in @history
	# 		for command, j in batch.commands

	# 			# Mulligan
	# 			# Add only one command for mulligan start, no need for both
	# 			if (command[0] == 'receiveTagChange' && command[1][0].entity == 2 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
	# 				@turns[turnNumber] = {
	# 					historyPosition: i
	# 					turn: 'Mulligan'
	# 					playerMulligan: []
	# 					opponentMulligan: []
	# 					timestamp: batch.timestamp
	# 					actions: []
	# 				}
	# 				@turns.length++
	# 				turnNumber++
	# 				currentPlayer = players[++playerIndex % 2]

	# 			if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 3 && command[1][0].tag == 'MULLIGAN_STATE' && command[1][0].value == 1)
	# 				currentPlayer = players[++playerIndex % 2]	

	# 			# Start of turn
	# 			if (command[0] == 'receiveTagChange' && command[1].length > 0 && command[1][0].entity == 1 && command[1][0].tag == 'STEP' && command[1][0].value == 6)
	# 				@turns[turnNumber] = {
	# 					historyPosition: i
	# 					turn: turnNumber - 1
	# 					timestamp: batch.timestamp
	# 					actions: []
	# 					activePlayer: currentPlayer
	# 				}
	# 				@turns.length++
	# 				turnNumber++
	# 				currentPlayer = players[++playerIndex % 2]

	# 			# # Draw cards - 1 - Simply a card arriving in hand
	# 			# if command[0] == 'receiveTagChange' and command[1][0].tag == 'ZONE' and command[1][0].value == 3
	# 			# 	# Don't add card draws that are at the beginning of the game or during Mulligan
	# 			# 	if currentTurnNumber >= 1

	# 			# 		currentCommand = command[1][0]
	# 			# 		while currentCommand and currentCommand.entity not in ['2', '3']
	# 			# 			currentCommand = currentCommand.parent
	# 			# 		if !currentCommand
	# 			# 			console.warn 'no one drew this card????', command[1][0]
						
	# 			# 		action = {
	# 			# 			turn: currentTurnNumber
	# 			# 			timestamp: batch.timestamp
	# 			# 			actionType: 'card-draw'
	# 			# 			type: ' draws '
	# 			# 			data: @entities[command[1][0].entity]
	# 			# 			owner: @entities[currentCommand.entity]
	# 			# 			initialCommand: command[1][0]
	# 			# 		}
	# 			# 		@addAction currentTurnNumber, action


	# 			if command[0] == 'receiveTagChange' and command[1][0].tag == 'NUM_CARDS_DRAWN_THIS_TURN' and command[1][0].value > 0
	# 				# Don't add card draws that are at the beginning of the game
	# 				if @turns[currentTurnNumber]
	# 					action = {
	# 						turn: currentTurnNumber
	# 						timestamp: batch.timestamp
	# 						actionType: 'card-draw'
	# 						type: ' draws '
	# 						data: @entities[playedCard]
	# 						owner: @entities[command[1][0].entity]
	# 						initialCommand: command[1][0]
	# 					}
	# 					@addAction currentTurnNumber, action

	# 			# The actual actions
	# 			if (command[0] == 'receiveAction')
	# 				currentTurnNumber = turnNumber - 1
	# 				if (@turns[currentTurnNumber])

	# 					# Mulligan
	# 					if command[1][0].attributes.type == '5' and currentTurnNumber == 1 and command[1][0].hideEntities
	# 						@turns[currentTurnNumber].playerMulligan = command[1][0].hideEntities
	# 					# Mulligan opponent
	# 					if command[1][0].attributes.type == '5' and currentTurnNumber == 1 and command[1][0].attributes.entity != @mainPlayerId
	# 						mulliganed = []
	# 						for tag in command[1][0].tags
	# 							if tag.tag == 'ZONE' and tag.value == 2
	# 								@turns[currentTurnNumber].opponentMulligan.push tag.entity


	# 					# Played a card
	# 					if command[1][0].tags and command[1][0].attributes.type != '5'

	# 						playedCard = -1

	# 						excluded = false
	# 						secret = false
	# 						for tag in command[1][0].tags
	# 							#console.log '\ttag', tag.tag, tag.value, tag
	# 							# Either in play or a secret
	# 							if tag.tag == 'ZONE' and tag.value in [1, 7]
	# 								playedCard = tag.entity
	# 							if tag.tag == 'SECRET' and tag.value == 1
	# 								secret = true
	# 								publicSecret = command[1][0].attributes.type == '7' and @turns[currentTurnNumber].activePlayer.id == @mainPlayerId
	# 							# Those are effects that are added to a creature (like Cruel Taskmaster's bonus)
	# 							# We don't want to treat them as a significant action, so we ignore them
	# 							if tag.tag == 'ATTACHED'
	# 								excluded = true

	# 						if playedCard > -1 and !excluded
	# 							#console.log 'batch', i, batch
	# 							#console.log '\tcommand', j, command
	# 							#console.log '\t\tadding action to turn', currentTurnNumber, command[1][0].tags, command
	# 							action = {
	# 								turn: currentTurnNumber - 1
	# 								# index: actionIndex++
	# 								timestamp: batch.timestamp
	# 								type: ': '
	# 								secret: secret
	# 								publicSecret: publicSecret
	# 								# If it's a secret, we want to know who put it in play
	# 								data: @entities[playedCard]
	# 								owner: @turns[currentTurnNumber].activePlayer
	# 								initialCommand: command[1][0]
	# 								debugType: 'played card'
	# 							}
	# 							@addAction currentTurnNumber, action
	# 							#console.log '\t\tadding action to turn', @turns[currentTurnNumber].actions[actionIndex]

	# 					# Secret revealed
	# 					if command[1][0].attributes.entity and command[1][0].attributes.type == '5'
	# 						entity = @entities[command[1][0].attributes.entity]
	# 						if entity.tags.SECRET == 1
	# 							console.log '\tyes', entity, command[1][0]
	# 							action = {
	# 								turn: currentTurnNumber - 1
	# 								# index: actionIndex++
	# 								# Used to make sure that revealed secrets occur after the action that triggered them
	# 								timestamp: batch.timestamp + 0.01
	# 								actionType: 'secret-revealed'
	# 								data: entity
	# 								# owner: @turns[currentTurnNumber].activePlayer
	# 								initialCommand: command[1][0]
	# 							}
	# 							@addAction currentTurnNumber, action


	# 					# Card revealed
	# 					# TODO: Don't add this when a spell is played, since another action already handles this
	# 					# Also, don't reveal enchantments as "showentities"
	# 					if command[1][0].showEntity and (command[1][0].attributes.type == '1' or (command[1][0].attributes.type != '3' and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)))

	# 						#console.log 'considering action for entity ' + command[1][0].showEntity.id, command[1][0].showEntity.tags, command[1][0]
	# 						playedCard = -1

	# 						# Revealed entities can start in the PLAY zone
	# 						if command[1][0].showEntity.tags
	# 							for entityTag, tagValue of command[1][0].showEntity.tags
	# 								#console.log '\t\tLooking at ', entityTag, tagValue
	# 								if (entityTag == 'ZONE' && tagValue == 1)
	# 									playedCard = command[1][0].showEntity.id

	# 						# Don't consider mulligan choices for now
	# 						if command[1][0].tags
	# 							for tag in command[1][0].tags
	# 								#console.log '\ttag', tag.tag, tag.value, tag
	# 								if (tag.tag == 'ZONE' && tag.value == 1)
	# 									playedCard = tag.entity

	# 						if (playedCard > -1)
	# 							#console.log '\tconsidering further'
	# 							action = {
	# 								turn: currentTurnNumber - 1
	# 								# index: actionIndex++
	# 								timestamp: batch.timestamp
	# 								type: ': '
	# 								data: if @entities[command[1][0].showEntity.id] then @entities[command[1][0].showEntity.id] else command[1][0].showEntity
	# 								owner: @turns[currentTurnNumber].activePlayer
	# 								debugType: 'showEntity'
	# 								debug: command[1][0].showEntity
	# 								initialCommand: command[1][0]
	# 							}
	# 							if (action.data)
	# 								#console.log 'batch', i, batch
	# 								#console.log '\tcommand', j, command
	# 								#console.log '\t\tadding showEntity', command[1][0].showEntity, action
	# 								@addAction currentTurnNumber, action

	# 					# Other trigger
	# 					if command[1][0].tags and command[1][0].attributes.type == '5'

	# 						playedCard = -1
	# 						#if command[1][0].attributes.entity == '49'
	# 							#console.log 'considering action', currentTurnNumber, command[1][0].tags, command

	# 						excluded = false
	# 						secret = false
	# 						for tag in command[1][0].tags
	# 							#console.log '\ttag', tag.tag, tag.value, tag
	# 							# Either in play or a secret
	# 							if tag.tag == 'ZONE' and tag.value in [1, 7]
	# 								playedCard = tag.entity
	# 							if tag.tag == 'SECRET' and tag.value == 1
	# 								secret = true
	# 							# Those are effects that are added to a creature (like Cruel Taskmaster's bonus)
	# 							# We don't want to treat them as a significant action, so we ignore them
	# 							if tag.tag == 'ATTACHED'
	# 								excluded = true

	# 						if playedCard > -1 and !excluded
	# 							#console.log 'batch', i, batch
	# 							#console.log '\tcommand', j, command
	# 							#console.log '\t\tadding action to turn', currentTurnNumber, command[1][0].tags, command
	# 							action = {
	# 								turn: currentTurnNumber - 1
	# 								# index: actionIndex++
	# 								timestamp: batch.timestamp
	# 								type: ': '
	# 								secret: secret
	# 								data: @entities[playedCard]
	# 								# It's a trigger, we log who caused it to trigger
	# 								owner: command[1][0].attributes.entity
	# 								initialCommand: command[1][0]
	# 								debugType: 'played card from tigger'
	# 							}
	# 							@addAction currentTurnNumber, action
	# 							#console.log '\t\tadding action to turn', @turns[currentTurnNumber].actions[actionIndex]

	# 					# Trigger with targets (or play that triggers some effects with targets, like Antique Healbot)
	# 					if command[1][0].tags and command[1][0].attributes.type in ['3', '5'] and command[1][0].meta?.length > 0
	# 						for meta in command[1][0].meta
	# 							for info in meta.info
	# 								# Don't add targeted triggers if parent is already targeted - we would log the same thing twice
	# 								if meta.meta == 'TARGET' and meta.info?.length > 0 and (!command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) != info.entity)
	# 										action = {
	# 											turn: currentTurnNumber - 1
	# 											# index: actionIndex++
	# 											timestamp: batch.timestamp
	# 											target: info.entity
	# 											type: ': trigger '
	# 											data: @entities[command[1][0].attributes.entity]
	# 											owner: @getController(@entities[command[1][0].attributes.entity].tags.CONTROLLER) #@turns[currentTurnNumber].activePlayer
	# 											initialCommand: command[1][0]
	# 											debugType: 'trigger effect card'
	# 										}
	# 										@addAction currentTurnNumber, action
	# 										#console.log 'Added action', action

	# 					# Deaths. Not really an action, but useful to see clearly what happens
	# 					if command[1][0].tags and command[1][0].attributes.type == '6' 

	# 						for tag in command[1][0].tags
	# 							# Graveyard
	# 							if (tag.tag == 'ZONE' && tag.value == 4)
	# 								action = {
	# 									turn: currentTurnNumber - 1
	# 									# index: actionIndex++
	# 									timestamp: batch.timestamp
	# 									type: ' died '
	# 									owner: tag.entity
	# 									initialCommand: command[1][0]
	# 								}
	# 								@addAction currentTurnNumber, action

	# 					# Attacked something
	# 					if parseInt(command[1][0].attributes.target) > 0 and (command[1][0].attributes.type == '1' or !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0)
	# 						#console.log 'considering attack', command[1][0]
	# 						action = {
	# 							turn: currentTurnNumber - 1
	# 							# index: actionIndex++
	# 							timestamp: batch.timestamp
	# 							type: ': '
	# 							actionType: 'attack'
	# 							data: @entities[command[1][0].attributes.entity]
	# 							owner: @turns[currentTurnNumber].activePlayer
	# 							target: command[1][0].attributes.target
	# 							initialCommand: command[1][0]
	# 							debugType: 'attack with complex conditions'
	# 						}
	# 						@addAction currentTurnNumber, action
	# 						#console.log '\t\tadding attack to turn', @turns[currentTurnNumber].actions[actionIndex]

	# 					# Card powers. Maybe something more than just battlecries?
	# 					# This also includes all effects from spells, which is too verbose. Don't add the action
	# 					# if it results from a spell being played
	# 					# 5 is to include triggering effects, like Piloted Shredder summoning of a minion
	# 					if command[1][0].attributes.type in ['3' ,'5']

	# 						# If parent action has a target, do nothing
	# 						if !command[1][0].parent or !command[1][0].parent.attributes.target or parseInt(command[1][0].parent.attributes.target) <= 0

	# 							# Does it do damage?
	# 							if command[1][0].tags
	# 								dmg = 0
	# 								target = undefined
	# 								for tag in command[1][0].tags
	# 									if (tag.tag == 'DAMAGE' && tag.value > 0)
	# 										dmg = tag.value
	# 										target = tag.entity

	# 								if dmg > 0
	# 									action = {
	# 										turn: currentTurnNumber - 1
	# 										# index: actionIndex++
	# 										timestamp: batch.timestamp
	# 										prefix: '\t'
	# 										type: ': '
	# 										data: @entities[command[1][0].attributes.entity]
	# 										owner: @turns[currentTurnNumber].activePlayer
	# 										# Don't store the full entity, because it's possible the target 
	# 										# doesn't exist yet when parsing the replay
	# 										# (it's the case for created tokens)
	# 										#@entities[target]
	# 										target: target
	# 										initialCommand: command[1][0]
	# 										debugType: 'power 3 dmg'
	# 									}
	# 									@addAction currentTurnNumber, action

	# 							# Don't include enchantments - we are already logging the fact that they are played
	# 							if command[1][0].fullEntity and command[1][0].fullEntity.tags.CARDTYPE != 6

	# 								# Also log what creates the new entities. Can be hero power 
	# 								# HP are logged in a bit of a weird way, so we need to manually adjust their offset
	# 								if command[1][0].parent
	# 									for tag in command[1][0].parent.tags
	# 										if (tag.tag == 'HEROPOWER_ACTIVATIONS_THIS_TURN' && tag.value > 0)
	# 											command[1][0].indent = if command[1][0].indent > 1 then command[1][0].indent - 1 else undefined
	# 											command[1][0].fullEntity.indent = if command[1][0].fullEntity.indent > 1 then command[1][0].fullEntity.indent - 1 else undefined
									
	# 								action = {
	# 									turn: currentTurnNumber - 1
	# 									# index: actionIndex++
	# 									timestamp: batch.timestamp
	# 									prefix: '\t'
	# 									type: ': '
	# 									data: @entities[command[1][0].attributes.entity]
	# 									owner: @turns[currentTurnNumber].activePlayer
	# 									initialCommand: command[1][0]
	# 									debugType: 'power 3 root'
	# 								}
	# 								@addAction currentTurnNumber, action

	# 								action = {
	# 									turn: currentTurnNumber - 1
	# 									# index: actionIndex++
	# 									timestamp: batch.timestamp
	# 									prefix: '\t'
	# 									creator: @entities[command[1][0].attributes.entity]
	# 									type: ': '
	# 									# This caused invoked minions from triggers to be detected as the minion who triggered them
	# 									#data: @entities[command[1][0].attributes.entity]
	# 									data: @entities[command[1][0].fullEntity.id]
	# 									owner: @getController(command[1][0].fullEntity.tags.CONTROLLER) #@turns[currentTurnNumber].activePlayer
	# 									# Don't store the full entity, because it's possible the target 
	# 									# doesn't exist yet when parsing the replay
	# 									# (it's the case for created tokens)
	# 									#@entities[target]
	# 									target: target
	# 									initialCommand: command[1][0].fullEntity
	# 									debugType: 'power 3'
	# 									debug: @entities
	# 								}
	# 								@addAction currentTurnNumber, action

	# 							# Armor buff
	# 							if command[1][0].tags
	# 								armor = 0
	# 								for tag in command[1][0].tags
	# 									if tag.tag == 'ARMOR' and tag.value > 0
	# 										armor = tag.value

	# 								if armor > 0
	# 									action = {
	# 										turn: currentTurnNumber - 1
	# 										# index: actionIndex++
	# 										timestamp: batch.timestamp
	# 										prefix: '\t'
	# 										type: ': '
	# 										data: @entities[command[1][0].attributes.entity]
	# 										owner: @getController(@entities[command[1][0].attributes.entity].tags.CONTROLLER)
	# 										initialCommand: command[1][0]
	# 										debugType: 'armor'
	# 									}
	# 									@addAction currentTurnNumber, action

	# 		#console.log @turns.length, 'game turns at position', @turns

	# 	# Sort the actions chronologically
	# 	tempTurnNumber = 1
	# 	while @turns[tempTurnNumber]
	# 		sortedActions = _.sortBy @turns[tempTurnNumber].actions, 'timestamp'
	# 		# console.log 'sorted actions', tempTurnNumber, @turns[tempTurnNumber].actions, sortedActions
	# 		@turns[tempTurnNumber].actions = sortedActions
	# 		tempTurnNumber++

	# 	# Find out who is the main player (the one who recorded the game)
	# 	# We use the revealed cards in hand to know this
	# 	#console.log 'finalizing init, player are', @player, @opponent, @players
	# 	if (parseInt(@opponent.id) == parseInt(@mainPlayerId))
	# 		@switchMainPlayer()
	# 		#tempOpponent = @player
	# 		#@player = @opponent
	# 		#@opponent = tempOpponent

	# 	@emit 'game-generated', this
	# 	@emit 'players-ready'

	# addAction: (currentTurnNumber, action) ->
	# 	# Actions are registered in batches in the XML (and the game), but we need to make sure that the parent 
	# 	# actions happen before
	# 	if action.initialCommand.parent and action.initialCommand.parent.timestamp == action.timestamp
	# 		action.timestamp += 0.01
	# 	@turns[currentTurnNumber].actions.push action

	switchMainPlayer: ->
		tempOpponent = @player
		@player = @opponent
		@opponent = tempOpponent

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

module.exports = ReplayPlayer
