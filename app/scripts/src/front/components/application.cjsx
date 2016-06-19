React = require 'react'
# {Window, Toolbar} = require 'react-photonkit'

module.exports = Application = React.createClass
	render: ->
		#console.log('rendering application')
		<div className="application">
			{@props.children}
		</div>

	componentDidMount: ->
		# Redirect straight to the replay for now
		@props.history.push('/replay')
