{Emitter} = require 'event-kit'
{zones, zoneNames} = require './enums'
_ = require 'lodash'
EventEmitter = require 'events'

class Entity extends EventEmitter
	constructor: (@replay) ->
		EventEmitter.call(this)
		@tags = {}

	getController: ->
		if @replay.player?.tags.CONTROLLER is @tags.CONTROLLER
			return @replay.player
		else if @replay.opponent?.tags.CONTROLLER is @tags.CONTROLLER
			return @replay.opponent
		return null

	getLastController: ->
		if @replay.player?.tags.CONTROLLER is @lastController
			return @replay.player
		else if @replay.opponent?.tags.CONTROLLER is @lastController
			return @replay.opponent
		return null

	getEnchantments: ->
		enchantments = _.filter @replay.entities, (entity) =>
			entity.tags.ZONE is zones.PLAY and entity.tags.ATTACHED is @tags.ENTITY_ID

		return enchantments

	update: (definition, action) ->
		old = _.assign {}, @tags
		# console.log 'updating entity', this, definition, action

		if definition.tags.ZONE
			@lastZone = old.ZONE
		if definition.tags.CONTROLLER
			@lastController = old.CONTROLLER

		if definition.id
			@id = definition.id
		if definition.tags
			if action
				# console.log 'updating entity', definition, action
				action.rollbackInfo[@id] = action.rollbackInfo[@id] || {}
			for k, v of definition.tags
				if action
					# Always keep the oldest
					# console.log '\tsetting property', @id, action.rollbackInfo, action.rollbackInfo[@id], k, v, @tags[k]
					action.rollbackInfo[@id][k] = action.rollbackInfo[@id][k] || @tags[k]
				@tags[k] = v

		# console.log 'update first pass done'
		if definition.cardID
			@cardID = definition.cardID
			# @emit 'revealed', entity: this
		if definition.name
			@name = definition.name

		changed = _.pick definition.tags, (value, tag) ->
			value isnt old[tag]

		# for tag, value of changed
		# 	if value isnt old[tag]
				# @emit "tag-changed:#{tag}",
				# 	entity: this
				# 	oldValue: old[tag]
				# 	newValue: value

		# if changed.ZONE
		# 	if old.ZONE
		# 		# @emit "left-#{zoneNames[old.ZONE].toLowerCase()}", entity: this
		# 		if old.ZONE is zones.DECK
		# 			@getController()?.entityLeftDeck(this)
		# 	# @emit "entered-#{zoneNames[changed.ZONE].toLowerCase()}", entity: this
		# 	if changed.ZONE is zones.HAND
		# 		@getController()?.entityEnteredHand(this)
		# 	if changed.ZONE is zones.PLAY
		# 		@getController()?.entityEnteredPlay(this)
		# 	if changed.ZONE is zones.DECK
		# 		@getController()?.entityEnteredDeck(this)
		# 	if changed.ZONE is zones.SECRET
		# 		@getController()?.entityEnteredSecret(this)

		# if changed.CONTROLLER
		# 	if old.ZONE is zones.HAND
		# 		# @emit 'left-hand', entity: this
		# 		@getController()?.entityEnteredHand(this)
		# 	if old.ZONE is zones.PLAY
		# 		# @emit 'left-play', entity: this
		# 		@getController()?.entityEnteredPlay(this)
		# 	if old.ZONE is zones.DECK
		# 		# @emit 'left-deck', entity: this
		# 		@getController()?.entityEnteredDeck(this)
		# 	if old.ZONE is zones.SECRET
		# 		# @emit 'left-secret', entity: this
		# 		@getController()?.entityEnteredSecret(this)

	getLastZone: -> @lastZone

	# newStep: ->
	# 	@emit 'new-step'

	# reinit: ->
	# 	@emit 'reset'
		
module.exports = Entity
