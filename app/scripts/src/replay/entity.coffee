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

			# Keep track of concedes
			if definition.tags.PLAYSTATE is 8
				@tags['CONCEDED'] = 1

		# console.log 'update first pass done'
		if definition.cardID
			@cardID = definition.cardID
			# @emit 'revealed', entity: this
		if definition.name
			@name = definition.name


	getLastZone: -> @lastZone

	# newStep: ->
	# 	@emit 'new-step'

	# reinit: ->
	# 	@emit 'reset'
		
module.exports = Entity
