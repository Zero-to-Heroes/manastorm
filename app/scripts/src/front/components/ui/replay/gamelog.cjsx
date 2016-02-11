React = require 'react'
SubscriptionList = require '../../../../subscription-list'

class GameLog extends React.Component
	componentDidMount: ->
		@subs = new SubscriptionList

		@replay = @props.replay
		@logIndex = 0

		@subs.add @replay, 'new-log', (log) =>
			@log = log
			@forceUpdate()

	render: ->
		<div className="game-log">
			{@log} 
			<button className="btn btn-default" onClick={@props.onLogClick}><span>Full log</span></button>
		</div>


module.exports = GameLog