React = require 'react'
RenderedCard = require './card/rendered-card'

ActiveSpell = React.createClass
	componentDidMount: ->

	render: ->
		@spell = @props.replay.activeSpell

		return null unless @spell

		# console.log 'rendering activeSpell', @spell
		return 	<RenderedCard entity={@spell} key={@spell.id} ref={@spell.id} cardUtils={@props.replay.cardUtils} replay={@props.replay} conf={@props.conf} className="active-spell" useBigFont={true} />

	getCardsMap: ->
		result = {}

		if !@spell
			return result

		result[@spell.id] = this.refs[@spell.id]
		# console.log 'returning activeSpell map', result

		return result

module.exports = ActiveSpell
