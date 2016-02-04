React = require 'react'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

Turn = React.createClass

	render: ->
		return null unless @props.replay

		cls = 'current-turn'
		if @props.active
			cls += ' active' 

		return 	<div className={cls} onClick={@props.onClick} >
					<span>{@props.replay.getCurrentTurnString()}</span>
				</div>


module.exports = Turn
