React = require 'react'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'
{subscribe} = require '../../../../subscription'

class EndGame extends React.Component

	render: ->
		# console.log 'rendering endgame?', @props.entity
		# WON, LOST, CONCEDED
		return null unless @props.isEnd

		if @props.entity.tags.PLAYSTATE is 4
			state = <span> Won</span>
		else if @props.entity.tags.PLAYSTATE is 5
			if @props.entity.tags.CONCEDED is 1
				state = <span> Conceded</span>
			else
				state = <span> Lost</span>

		else if @props.entity.tags.PLAYSTATE is 6
			state = <span> Tied</span>

		return  <div className="end-state">
					<span>{@props.entity.name}</span>
					{state}
				</div>

module.exports = EndGame
