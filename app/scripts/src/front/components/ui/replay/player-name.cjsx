React = require 'react'

class PlayerName extends React.Component
	render: ->
		# console.log 'rendering PlayerName'
		cls = "player-name"
		if @props.isActive
			cls += " active"
		name = @props.entity.name
		if name.indexOf('#') != -1
			name = @props.entity.name.substring(0, name.lastIndexOf('#'))
		return <div className={cls}>
			{name}
		</div>

module.exports = PlayerName
