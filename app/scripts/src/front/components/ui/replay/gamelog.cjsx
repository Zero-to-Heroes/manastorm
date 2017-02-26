React = require 'react'
SubscriptionList = require '../../../../subscription-list'

class GameLog extends React.Component
	componentDidMount: ->
		@subs = new SubscriptionList

		@replay = @props.replay
		@logIndex = 0

		@subs.add @replay, 'new-log', (log) =>
			@log = log

	render: ->
		# console.log 'rendering gamelog'
		# clear lingering tooltips - not good design
		@replay?.cardUtils?.destroyTooltips?()

		buttonText = <span>Full log</span>
		if @props.logOpen
			buttonText = <span>Hide log</span>

		if !@props.hide
			button = <button className="btn btn-default" onClick={@props.onLogClick}>{buttonText}</button>

		<div className="game-log">
			{@log} 
		</div>


module.exports = GameLog