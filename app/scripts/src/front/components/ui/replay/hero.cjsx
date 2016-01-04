React = require 'react'
Card = require './card'
HeroCard = require './herocard'

Hero = React.createClass
	componentDidMount: ->

	render: ->
		return null unless @props.entity.tags.MULLIGAN_STATE is 4

		@hero = @props.entity.getHero()
		@heroPower = @props.entity.getHeroPower()
		@secrets = @props.entity.getSecrets()
		#console.log 'setting entity', @hero, @heroPower
		hidden = false
			
		return 	<div className="hero">
					<HeroCard entity={@hero} key={@hero.id} secrets={@secrets} isHidden={hidden} ref={@hero.id} className="avatar"/>
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
