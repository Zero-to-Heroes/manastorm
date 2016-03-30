React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
Armor = require './armor'
HeroAttack = require './heroAttack'
{subscribe} = require '../../../../subscription'

class HeroCard extends Card

	render: ->
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{@props.entity.cardID}.png"

		weapon = @props.weapon

		if @props.entity.cardID && !@props.isHidden
			style =
				background: "url(#{art}) top left no-repeat"
				backgroundSize: '100% auto'
			cls = "game-card"

		if @props.className
			cls += " " + @props.className

		if @props.entity.tags.FROZEN
			overlay = <div className="overlay frozen"></div>

		if @props.entity.highlighted
			cls += " option-on"
			
		if @props.secrets
			show = @props.showSecrets
			secrets = @props.secrets.map (entity) ->
				<Secret entity={entity} key={entity.id} showSecret={show}/>
			#console.log 'rendering secrets', @props.secrets, secrets

		@props.entity.damageTaken = @props.entity.damageTaken or 0
		if @props.entity.tags.DAMAGE - @props.entity.damageTaken > 0
			damage = <span className="damage">{-(@props.entity.tags.DAMAGE - @props.entity.damageTaken)}</span>

		return 	<div className={cls} style={style}>
					<HeroAttack entity={@props.entity} weapon={weapon}/>
					{secrets}
					<Armor entity={@props.entity}/>
					<Health entity={@props.entity}/>
					{damage}
				</div>

module.exports = HeroCard
