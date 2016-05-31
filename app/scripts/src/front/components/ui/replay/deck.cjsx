React = require 'react'
{subscribe} = require '../../../../subscription'

class Deck extends React.Component
	componentDidMount: ->
		# subscribe @props.entity, 'entity-left-deck entity-entered-deck', =>
		# 	@forceUpdate()

	render: ->
		return <div className="deck">
			<span>{@props.entity.getDeck().length}</span>
		</div>

module.exports = Deck
