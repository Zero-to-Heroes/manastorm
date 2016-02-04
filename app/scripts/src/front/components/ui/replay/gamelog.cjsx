React = require 'react'
SubscriptionList = require '../../../../subscription-list'

class GameLog extends React.Component
	componentDidMount: ->
		@subs = new SubscriptionList

		@replay = @props.replay

		@subs.add @replay, 'new-log', (log) =>
			@log = log
			@forceUpdate()

	render: ->
		<div className="game-log">
			{@log}
		</div>


module.exports = GameLog