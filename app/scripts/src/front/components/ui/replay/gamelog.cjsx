React = require 'react'
$ = require 'jquery'
bt = require 'react-bootstrap'

class GameLog extends React.Component
	componentDidMount: ->
		#@int = setInterval((=> @forceUpdate()), 500)

	render: ->
		@replay = @props.replay

		<div className="game-log">
			<p dangerouslySetInnerHTML={{__html: @replay.turnLog}}></p>
		</div>


module.exports = GameLog