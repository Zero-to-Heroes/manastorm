React = require 'react'
Card = require './card'

Hero = React.createClass
	componentDidMount: ->

	render: ->
		return null unless @props.entity.tags.MULLIGAN_STATE is 4

		hero = @props.entity.getHero()
		heroPower = @props.entity.getHeroPower()
		console.log 'setting entity', hero, heroPower
		hidden = false
			
		return 	<div className="hero">
					<Card entity={hero} key={hero.id} isHidden={hidden} className="avatar"/>
					<Card entity={heroPower} key={heroPower.id} isHidden={hidden} className="power"/>
				</div>


module.exports = Hero
