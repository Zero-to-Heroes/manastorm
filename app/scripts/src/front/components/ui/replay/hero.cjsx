React = require 'react'
Card = require './card'
HeroCard = require './herocard'
HeroPower = require './heropower'
Weapon = require './weapon'

Hero = React.createClass
	componentDidMount: ->

	render: ->
		@hero = @props.entity.getHero()
		@heroPower = @props.entity.getHeroPower()
		@weapon = @props.entity.getWeapon()
		@secrets = @props.entity.getSecrets()
		# console.log 'rendering hero', @props.entity.cardId, @props.entity.tags
		cardUtils = @props.replay.cardUtils
		conf = @props.conf

		return 	<div className="hero">
					<Weapon entity={@weapon} key={@weapon?.id} ref={@weapon?.id} cardUtils={cardUtils} replay={@props.replay} conf={conf}/>
					<HeroCard entity={@hero} weapon={@weapon} key={@hero.id} secrets={@secrets} ref={@hero.id} showSecrets={@props.showConcealedInformation} className="avatar" cardUtils={cardUtils} conf={conf} />
					<HeroPower entity={@heroPower} controller={@props.entity} key={@heroPower?.id} ref={@heroPower?.id} cardUtils={cardUtils} conf={conf}/>
				</div>

	getCardsMap: ->
		result = {}

		if !@hero || !@heroPower
			return result

		#console.log 'building cards map in hero', this.refs

		result[@hero.id] = this.refs[@hero.id]
		result[@heroPower.id] = this.refs[@heroPower.id]
		if @weapon
			result[@weapon.id] = this.refs[@weapon.id]

		#console.log '\tbuilt cards map', result

		return result

module.exports = Hero
