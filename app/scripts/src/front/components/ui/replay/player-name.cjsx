React = require 'react'

class PlayerName extends React.Component
	render: ->
		cls = "player-name"
		if @props.isActive
			cls += " active"
		return <div className={cls}>
			{@props.entity.name}
		</div>

module.exports = PlayerName
