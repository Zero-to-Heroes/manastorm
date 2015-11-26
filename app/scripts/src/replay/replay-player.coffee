Entity = require './entity'
Player = require './player'
HistoryBatch = require './history-batch'
_ = require 'lodash'
EventEmitter = require 'events'

class ReplayPlayer extends EventEmitter
	constructor: (@parser) ->
		EventEmitter.call(this)

		window.replay = this
		console.log 'player constructed'

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
		@startTime = (new Date).getTime()
		@currentReplayTime = 0

		@started = false
		@speed = 1

		@parser.parse(this)

	run: ->
		console.log 'running player'
		# @parser.parse(this)
		console.log 'parsed game'
		@frequency = 200
		@speed = @initialSpeed || 1
		@interval = setInterval((=> @update()), @frequency)

	start: (timestamp) ->
		console.log 'starting game at timestamp', timestamp
		# The timestamp recorded by the game for the beginning, don't tpich this
		@startTimestamp = timestamp
		@started = true

	pause: ->
		console.log 'pausing in replay-plyaer'
		@initialSpeed = @speed
		@speed = 0

	changeSpeed: (speed) ->
		console.log 'changing speed in replay', speed
		@speed = speed

	getSpeed: ->
		@speed

	getTotalLength: ->
		return @history[@history.length - 1].timestamp - @startTimestamp

	#getElapsed: ->
	#	((new Date).getTime() - @startTime) / 1000

	getElapsed: ->
		#console.log 'elapsed2 is ', @currentReplayTime
		@currentReplayTime / 1000

	getTimestamps: ->
		return _.map @history, (batch) => batch.timestamp - @startTimestamp

	moveTime: (progression) ->
		target = @getTotalLength() * progression * 1000
		console.log 'moving to', target
		@goToTimestamp target

	goToTimestamp: (timestamp) ->
		initialSpeed = @speed

		if (timestamp < @currentReplayTime)
			console.log 'resetting'
			@init()
			@historyPosition = 0

		@start(@startTimestamp)

		if (!@interval)
			console.log 'running the game'
			@run()
			@changeSpeed(initialSpeed)

		console.log 'going to timestamp in replay', timestamp
		@currentReplayTime = timestamp

		@emit 'moved-timestamp'

	update: ->
		# console.log 'on update', this
		@currentReplayTime += @frequency * @speed
		if (@currentReplayTime >= @getTotalLength() * 1000)
			@currentReplayTime = @getTotalLength() * 1000

		elapsed = @getElapsed()
		while @historyPosition < @history.length
			if elapsed > @history[@historyPosition].timestamp - @startTimestamp
				#console.log 'processing ', @history[@historyPosition]
				@history[@historyPosition].execute(this)
				@historyPosition++
			else
				break

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

	receiveEntity: (definition) ->
		#console.log 'receiving entity', definition
		if @entities[definition.id]
			entity = @entities[definition.id]
		else
			entity = new Entity(this)

		@entities[definition.id] = entity
		entity.update(definition)
		if definition.id is 68
			if definition.cardID is 'GAME_005'
				@player = entity.getController()
				@opponent = @player.getOpponent()
			else
				@opponent = entity.getController()
				@player = @opponent.getOpponent()

			console.log 'emitting player-ready event'
			@emit 'players-ready'

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

module.exports = ReplayPlayer
