React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
Armor = require './armor'
HeroAttack = require './heroAttack'
ReactTooltip = require 'react-tooltip'
{subscribe} = require '../../../../subscription'

class HeroCard extends Card

	render: ->
		# console.log 'rendering HeroCard'
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''

		entity = @props.entity
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{entity.cardID}.png"

		weapon = @props.weapon

		# console.log 'rendering hero', entity.cardID, entity

		if entity.cardID && !@props.isHidden
			style =
				backgroundImage: "url(#{art})"
			cls = "game-card"
			avatarCls = "game-card"

		if @props.className
			cls += " " + @props.className

		overlays = []
		if entity.tags.FROZEN and entity.tags.FROZEN != 0
			overlays.push <div className="overlay frozen"></div>
		if entity.tags.HEAVILY_ARMORED and entity.tags.HEAVILY_ARMORED != 0
			overlays.push <div className="overlay heavily-armored"></div>
		if entity.tags.CANT_BE_DAMAGED and entity.tags.CANT_BE_DAMAGED != 0
			overlays.push <div className="overlay immune"></div>

		# console.log 'rendering hero', entity
		if entity.highlighted
			cls += " option-on"
			
		if @props.secrets
			show = @props.showSecrets
			secrets = @props.secrets.map (secret) ->
				<Secret entity={secret} key={secret.id} showSecret={show}/>
			#console.log 'rendering secrets', @props.secrets, secrets

		entity.damageTaken = entity.damageTaken or 0
		if entity.tags.DAMAGE - entity.damageTaken > 0
			damage = <span className="damage"><span>{-(entity.tags.DAMAGE - entity.damageTaken)}</span></span>

		# console.log 'build statuses', entity.cardID, entity
		statuses = @buildStatuses entity

		cardTooltip = 
			<div className="card-container">
				<div className='statuses'>
					<div className="filler"></div>
					{statuses}
				</div>
			</div>
			
		@updateDimensions()

		return 	<div className={cls} data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="50" data-class="card-tooltip">
					<div className="frame frame-highlight"></div>
					<div className={avatarCls} style={style}></div>
					<div className="frame"></div>
					{overlays}
					<div className="secrets">
						{secrets}
					</div>
					<HeroAttack entity={entity} weapon={weapon}/>
					<Health entity={entity}/>
					<Armor entity={entity}/>
					{damage}
					<ReactTooltip id={"" + entity.id} >
					    {cardTooltip}
					</ReactTooltip>
				</div>

module.exports = HeroCard
