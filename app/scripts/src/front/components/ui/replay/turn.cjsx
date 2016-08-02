React = require 'react'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

Turn = React.createClass

	render: ->
		return null unless @props.replay
		# console.log 'rendering turn'

		cls = 'current-turn'
		if @props.active
			cls += ' active' 

		return 	<div className={cls} onClick={@props.onClick} >
					<div className="text">
						<span>{@props.replay.getCurrentTurnString()}</span>
					</div>
				</div>


module.exports = Turn
