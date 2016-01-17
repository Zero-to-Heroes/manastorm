React = require 'react'
Card = require './card'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'
{subscribe} = require '../../../../subscription'

class Mulligan extends React.Component
	componentDidMount: ->
		@sub = subscribe @props.entity, 'tag-changed:MULLIGAN_STATE', ({newValue}) =>
			@forceUpdate()

	componentWillUnmount: ->
		#@sub.off()

	render: ->
		return null unless @props.entity.tags.MULLIGAN_STATE < 4

		#console.log 'rendering mulligan', @props.entity, @props.entity.getHand(), @props.mulligan
		hidden = @props.isHidden
		cards = @props.entity.getHand().slice(0, 4).map (entity) =>
			#console.log 'is card discarded', @props.mulligan.indexOf(entity.id) != -1, entity, @props.mulligan
			<Card entity={entity} key={entity.id} isHidden={hidden} isDiscarded={@props.mulligan.indexOf(entity.id) != -1} />

		return <ReactCSSTransitionGroup component="div" className="mulligan"
					transitionName="animate" transitionEnterTimeout={700}
					transitionLeaveTimeout={700}>
				{cards}
			</ReactCSSTransitionGroup>

module.exports = Mulligan
