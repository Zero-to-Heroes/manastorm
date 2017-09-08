React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")

Secret = require './Secret'
Health = require './health'

Card = require './card'
CardArt = require './card/card-art'
CardEffect = require './card/card-effect'
WeaponTooltip = require './card/weapon-tooltip'

class Weapon extends Card
	componentDidMount: ->

	render: ->
		#console.log 'trying to render weapon', @props.entity
		return <div className="weapon-container"></div> unless @props.entity?.cardID

		entity = @props.entity
		cardUtils = @props.cardUtils
		originalCard = cardUtils.getCard(@props.entity.cardID)

		art = <CardArt cardUtils={cardUtils} entity={entity} />
		weaponVisual = <img src="scripts/static/images/weapon_unsheathed.png" className="visual" />

		# console.log 'rendering weapon', @props.entity
		if entity.tags.CONTROLLER != @props.replay.getActivePlayer()?.tags?.PLAYER_ID
			weaponVisual = <img src="scripts/static/images/weapon_sheathed.png" className="visual" />

		cls = "weapon"
		if @props.className
			cls += " " + @props.className

		healthClass = "card__stats__health"
		if @props.entity.tags.DAMAGE > 0
			healthClass += " damaged"

		atkCls = "card__stats__attack"
		if originalCard
			originalAtk = originalCard.attack
			tagAtk = @props.entity.tags.ATK || originalAtk
			if tagAtk > originalAtk
				atkCls += " buff"
			else if tagAtk < originalAtk
				atkCls += " debuff"

		tagDurability = @props.entity.tags.DURABILITY || originalCard.durability
		stats = <div className="card__stats">
			<div className={atkCls}><span>{tagAtk or 0}</span></div>
			<div className={healthClass}><span>{tagDurability - (@props.entity.tags.DAMAGE or 0)}</span></div>
		</div>

		enchantments = @buildEnchantments entity
		statuses = @buildStatuses entity

		enchantmentClass = if enchantments?.length > 0 then 'enchantments' else ''

		imageCls = "game-card"
		if originalCard?.set?.toLowerCase() is 'gangs'
			# console.log '\tgangs card'
			imageCls += " msg-card"
			enchantmentClass += ' msg-card'

		cardTooltip =
			<div className="card-container">
				<div className="game-info">
					<img src={art} />
					<div className={enchantmentClass}>
						{enchantments}
					</div>
				</div>
				<div className='statuses'>
					<div className="filler"></div>
					{statuses}
				</div>
			</div>

		@updateDimensions()
		# link = '<img src="' + art + '">';

		return <div key={'card' + entity.id} className="weapon-container" data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="50" data-class="card-tooltip">
					<div className={cls}>
						{art}
						{weaponVisual}
						<CardEffect cardUtils={cardUtils} entity={entity} />
						{stats}
					</div>
					<ReactTooltip id={"" + entity.id} >
					    <WeaponTooltip isInfoConcealed={@props.isInfoConcealed} entity={entity} key={@props.entity.id} isHidden={@props.hidden} cost={true} cardUtils={cardUtils} controller={@props.controller} style={@props.style} conf={@props.conf} />
					</ReactTooltip>
				</div>

module.exports = Weapon
