React = require 'react'
Card = require './card'

ActiveSpell = React.createClass
	componentDidMount: ->

	render: ->
		console.log 'rendering activeSpell'
		@spell = @props.replay.activeSpell

		return null unless @spell

		return 	<Card entity={@spell} key={@spell.id} ref={@spell.id} className="active-spell"/>

	getCardsMap: ->
		result = {}

		if !@spell
			return result

		result[@spell.id] = this.refs[@spell.id]

		return result

module.exports = ActiveSpell
