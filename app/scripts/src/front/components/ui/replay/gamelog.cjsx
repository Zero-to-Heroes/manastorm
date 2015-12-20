React = require 'react'

class GameLog extends React.Component
	componentDidMount: ->
		@int = setInterval((=> @forceUpdate()), 500)

	render: ->
		@replay = @props.replay

		<div className="game-log">
			<p>{@replay.turnLog}</p>
		</div>

module.exports = GameLog