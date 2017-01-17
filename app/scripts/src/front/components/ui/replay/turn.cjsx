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

		turn = @props.replay.getCurrentTurn()
		if turn is 0
			turnDisplay = 'Mulligan'
		else if turn is 500
			turnDisplay = 'Endgame'
		else 
			turnDisplay = 'Turn ' + Math.ceil(turn / 2)

		if @props.replay.getActivePlayer()?.name
			turnDisplay += ' - ' + @props.replay.getActivePlayer().name

		console.log 'rendering turn button', turnDisplay, @props.replay.getActivePlayer()

		return 	<div className={cls} data-tip={turnDisplay} data-effect="solid">
					<div className="text">
						<span>{@props.replay.getCurrentTurnString()}</span>
					</div>
				</div>


module.exports = Turn
