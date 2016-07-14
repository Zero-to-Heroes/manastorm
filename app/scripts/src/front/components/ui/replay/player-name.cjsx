React = require 'react'

class PlayerName extends React.Component
	render: ->
		console.log 'rendering PlayerName'
		cls = "player-name"
		if @props.isActive
			cls += " active"
		return <div className={cls}>
			{@props.entity.name}
		</div>

module.exports = PlayerName
