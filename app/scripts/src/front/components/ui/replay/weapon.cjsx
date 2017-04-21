React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
ReactTooltip = require("react-tooltip")
{subscribe} = require '../../../../subscription'

class Weapon extends Card
	componentDidMount: ->

	render: ->
		#console.log 'trying to render weapon', @props.entity
		return <div className="weapon-container"></div> unless @props.entity?.cardID
		#console.log '\trendering weapon', @props.entity
		entity = @props.entity

		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{@props.entity.cardID}.png"
		originalCard = @props.cardUtils?.getCard(@props.entity.cardID)

		# console.log 'rendering weapon', @props.entity
		cls = "weapon"
		if @props.entity.tags.CONTROLLER != @props.replay.getActivePlayer().tags.PLAYER_ID
			# console.log 'shearthing', @props.replay.getActivePlayer().tags.PLAYER_ID, @props.entity
			cls += " sheathed"
			style = {}
		else 
			cls += " unsheathed"
			style =
				backgroundImage: "url(#{art})"

		if @props.className
			cls += " " + @props.className

		if entity.tags.POISONOUS
			effect = <div className="effect poisonous"></div>

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
						<div className={imageCls} style={style}></div>
						<div className="art"></div>
						{effect}
						{stats}
					</div>
					<ReactTooltip id={"" + entity.id} >
					    {cardTooltip}
					</ReactTooltip>
				</div>

module.exports = Weapon
