React = require 'react'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

Turn = React.createClass

	render: ->
		return null unless @props.replay

		return 	<div className="current-turn">
					<span>{@props.replay.getCurrentTurnString()}</span>
				</div>

module.exports = Turn
