React = require 'react'
Card = require './card'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

Hand = React.createClass
	componentDidMount: ->
		console.log 'Hand did mount'
		@subs = new SubscriptionList

		for entity in @props.entity.getHand()
			@subscribeToEntity(entity)

		@subs.add @props.entity, 'entity-entered-hand', ({entity}) =>
			console.log 'entity-entered-hand'
			@subscribeToEntity(entity)
			@forceUpdate()

		@subs.add @props.entity, 'tag-changed:MULLIGAN_STATE', =>
			console.log 'tag-changed:MULLIGAN_STATE'
			@forceUpdate()

	subscribeToEntity: (entity) ->
		entitySubs = @subs.add new SubscriptionList
		entitySubs.add entity, 'left-hand', =>
			entitySubs.off()
			@forceUpdate()
		entitySubs.add entity, 'tag-changed:ZONE_POSITION', =>
			@forceUpdate()

	componentWillUnmount: ->
		console.log 'hand will unmount'
		@subs.off()

	render: ->
		console.log 'rendering hand? ', @props.entity.tags, @props.entity.tags.MULLIGAN_STATE
		return null unless @props.entity.tags.MULLIGAN_STATE is 4

		console.log 'rendering hand'
		active = _.filter @props.entity.getHand(), (entity) -> entity.tags.ZONE_POSITION > 0

		cards = active.map (entity) ->
			<Card entity={entity} key={entity.id} />

		return <ReactCSSTransitionGroup component="div" className="hand"
					transitionName="animate" transitionEnterTimeout={700}
					transitionLeaveTimeout={700}>
				{cards}
			</ReactCSSTransitionGroup>


module.exports = Hand
