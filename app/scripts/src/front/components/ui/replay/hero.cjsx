React = require 'react'
Card = require './card'

Hero = React.createClass
	componentDidMount: ->

	render: ->
		return null unless @props.entity.tags.MULLIGAN_STATE is 4

		@hero = @props.entity.getHero()
		@heroPower = @props.entity.getHeroPower()
		#console.log 'setting entity', @hero, @heroPower
		hidden = false
			
		return 	<div className="hero">
					<Card entity={@hero} key={@hero.id} isHidden={hidden} ref={@hero.id} className="avatar"/>
					<Card entity={@heroPower} key={@heroPower.id} isHidden={hidden} ref={@heroPower.id} className="power"/>
				</div>

	getCardsMap: ->
		result = {}

		if !@hero || !@heroPower
			return result

		#console.log 'building cards map in hero', this.refs

		result[@hero.id] = this.refs[@hero.id]
		result[@heroPower.id] = this.refs[@heroPower.id]

		#console.log '\tbuilt cards map', result

		return result

module.exports = Hero
