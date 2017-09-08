React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")

Secret = require './Secret'
Health = require './health'

Card = require './card'
CardArt = require './card/card-art'
CardEffect = require './card/card-effect'
CardStats = require './card/card-stats'
WeaponVisual = require './card/weapon-visual'
CardTooltip = require './card-tooltip'

class Weapon extends Card
	componentDidMount: ->

	render: ->
		#console.log 'trying to render weapon', @props.entity
		return <div className="weapon-container"></div> unless @props.entity?.cardID

		entity = @props.entity
		cardUtils = @props.cardUtils
		originalCard = cardUtils.getCard(@props.entity.cardID)

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
					<img src='' />
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

		cls = "weapon rendered-card"
		if @props.className
			cls += " " + @props.className

		return <div key={'card' + entity.id} className="weapon-container" data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="10" data-class="card-tooltip rendered-card-tooltip">
					<div className={cls}>
						<CardArt cardUtils={cardUtils} entity={entity} />
						<WeaponVisual replay={@props.replay} cardUtils={cardUtils} entity={entity} />
						<CardEffect cardUtils={cardUtils} entity={entity} />
						<CardStats cardUtils={cardUtils} entity={entity} />
					</div>
					<ReactTooltip id={"" + entity.id} >
					    <CardTooltip isInfoConcealed={@props.isInfoConcealed} entity={entity} key={@props.entity.id} isHidden={@props.hidden} cost={true} cardUtils={cardUtils} controller={@props.controller} style={@props.style} conf={@props.conf} />
					</ReactTooltip>
				</div>

module.exports = Weapon
