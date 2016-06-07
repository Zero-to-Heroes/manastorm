React = require 'react'
Card = require './card'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

Hand = React.createClass
	componentDidMount: ->
		@subs = new SubscriptionList

		# for entity in @props.entity.getHand()
		# 	@subscribeToEntity(entity)

		# @subs.add @props.entity, 'entity-entered-hand', ({entity}) =>
		# 	@subscribeToEntity(entity)
		# 	@forceUpdate()

		# @subs.add @props.entity, 'tag-changed:MULLIGAN_STATE', =>
		# 	@forceUpdate()

	# subscribeToEntity: (entity) ->
	# 	entitySubs = @subs.add new SubscriptionList
	# 	entitySubs.add entity, 'left-hand', =>
	# 		entitySubs.off()
	# 		@forceUpdate()
	# 	entitySubs.add entity, 'tag-changed:ZONE_POSITION', =>
	# 		@forceUpdate()

	componentWillUnmount: ->
		#@subs.off()

	render: ->
		return <div className="hand"></div> unless @props.entity.tags.MULLIGAN_STATE is 4

		active = _.filter @props.entity.getHand(), (entity) -> entity.tags.ZONE_POSITION > 0

		hidden = @props.isHidden
		replay = @props.replay
		controller = @props.entity
		isInfoConcealed = @props.isInfoConcealed

		cards = active.map (entity) ->
			margin = -6
			if active.length == 7
				margin = -7
			if active.length == 8
				margin = -9
			else if active.length == 9
				margin = -10
			else if active.length == 10
				margin = -11

			style = { 
				marginLeft: margin + '%'
			}

			# console.log 'rendering card in hand', entity.cardID, entity
			<Card isInfoConcealed={isInfoConcealed} entity={entity} key={entity.id} isHidden={hidden} cost={true} cardUtils={replay.cardUtils} controller={controller} style={style}/>

		return <div className="hand">
				<div>{cards}</div>
			</div>


module.exports = Hand
