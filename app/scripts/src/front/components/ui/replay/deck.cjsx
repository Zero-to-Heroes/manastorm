React = require 'react'

class Deck extends React.Component

	render: ->
		# console.log 'rendering deck'
		return <div className="deck">
			<span>{@props.entity.getDeck().length}</span>
		</div>

module.exports = Deck
