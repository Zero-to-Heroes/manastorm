React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")
ReactFitText = require('react-fittext');
{subscribe} = require '../../../../subscription'

class CardInHand extends React.Component

	# TODO: for now only handle cards in hand, will handle the rest with subclassing / composition
	render: ->
		# console.log 'rendering card'
		# locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		cardUtils = @props.cardUtils
		entity = @props.entity

		cls = 'game-card rendered-card visible'

		if !entity.cardID or @props.isHidden
			return <div key={'card' + entity.id} className="game-card rendered-card" style={@props.style}>
				<div className="art card--unknown"></div>
			</div>

		# The card art
		cardArt = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/cardart/256x/#{entity.cardID}.jpg"

		originalCard = cardUtils?.getCard(entity.cardID)

		# The frames
		if originalCard.type is 'Minion'
			cls += ' minion'
			if entity.tags.PREMIUM is 1 and !@props.conf?.noGolden
				frame = 'inhand_minion_premium.png'
			else
				frame = 'frame-minion-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Spell'
			cls += ' spell'
			if entity.tags.PREMIUM is 1 and !@props.conf?.noGolden
				frame = 'inhand_spell_premium.png'
			else
				frame = 'frame-spell-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Weapon'
			cls += ' weapon'
			if entity.tags.PREMIUM is 1 and !@props.conf?.noGolden
				frame = 'inhand_weapon_premium.png'
			else
				frame = 'frame-weapon-' + originalCard.playerClass?.toLowerCase() + '.png'

		frame = 'scripts/static/images/card/' + frame

		# mana cost
		if @props.cost and !@props.isInfoConcealed
			costCls = "card-cost"
			# console.log 'getting card cost from', originalCard, entity
			originalCost = originalCard.cost
			if entity.tags.COST is 0
				tagCost = 0
			else
				tagCost = entity.tags.COST || originalCost
			if tagCost < originalCost
				costCls += " lower-cost"
			else if tagCost > originalCost
				costCls += " higher-cost"
			cost = <div className={costCls}><span>{tagCost or 0}</span></div>

		# name
		nameBanner = <img src={'scripts/static/images/card/name-banner-' + originalCard.type.toLowerCase() + '.png'} className="name-banner" />
		if originalCard.type is 'Minion'
			pathId = 'minionPath'
			path = <path id={pathId} d="M 0,20 C 50,30 150,-10 200,20" />
		else if originalCard.type is 'Spell'
			pathId = 'spellPath'
			path = <path id={pathId} d="M 0,30 Q 100,-10 200,30" />
		# TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
		else if originalCard.type is 'Weapon'
			pathId = 'weaponPath'
			path = <path id={pathId} d="M 0,20 C 50,30 150,-10 200,20" />

		nameText = <div className="name-text">
						<ReactFitText>
							<svg x="0" y ="0" width="100%" height="100%" viewBox="0 0 200 30">
								<defs>
									{path}
								</defs>
	    						<text textAnchor="middle">
	    							<textPath startOffset="50%" xlinkHref={'#' + pathId}>{originalCard.name}</textPath>
	    						</text>
							</svg>
						</ReactFitText>
					</div>

		# card text
		cardText = <div className="card-text">
					<ReactFitText>
						<p dangerouslySetInnerHTML={{ __html: originalCard.text?.replace('\n', '<br/>') }}></p>
					</ReactFitText>
				</div>

		# race
		if originalCard.race
			race = <div className="race">
						<img src={'scripts/static/images/card/race-banner.png'} className="race-banner" />
						<p>{originalCard.race.toLowerCase()}</p>
					</div>

		# rarity
		if originalCard.rarity and originalCard.rarity isnt 'Free'
			if originalCard.type is 'Minion'
				rarity = 'rarity-minion-' + originalCard.rarity.toLowerCase() + '.png'
				if originalCard.rarity.toLowerCase() is 'legendary'
					legendaryFrame = <img src={'scripts/static/images/card/legendary-minion.png'} className="legendary-frame"/>
			else if originalCard.type is 'Spell'
				rarity = 'rarity-spell-' + originalCard.rarity.toLowerCase() + '.png'
				if originalCard.rarity.toLowerCase() is 'legendary'
					legendaryFrame = <img src={'scripts/static/images/card/legendary-spell.png'} className="legendary-frame"/>
			else if originalCard.type is 'Weapon'
				rarity = 'rarity-weapon-' + originalCard.rarity.toLowerCase() + '.png'

			rarityImg = <img src={'scripts/static/images/card/' + rarity} className="rarity"/>

		# legendary - TODO
		# if originalCard?.rarity is 'Legendary'
		# 	legendaryCls = " legendary"

		if @props.className
			cls += " " + @props.className


		if (originalCard.attack or originalCard.health) and !@props.isInfoConcealed
			healthClass = "card__stats__health"
			atkCls = "card__stats__attack"

			originalAtk = originalCard.attack
			if entity.tags.ATK?
				tagAtk = entity.tags.ATK
			else
				tagAtk = originalAtk
			if tagAtk > originalAtk
				atkCls += " buff"
			else if tagAtk < originalAtk
				atkCls += " debuff"

			originalHealth = originalCard.health
			tagHealth = entity.tags.HEALTH || originalHealth
			if tagHealth > originalHealth
				healthClass += " buff"

			tagDurability = entity.tags.DURABILITY || originalCard.durability
			stats =
				<div className="card__stats">
					<div className={atkCls}><span>{tagAtk or 0}</span></div>
					<div className={healthClass}><span>{(tagHealth or tagDurability) - (entity.tags.DAMAGE or 0)}</span></div>
				</div>


		imageCls = "art "
		highlightCls = ''
		if entity.highlighted
			highlightCls += " option-on frame-highlight"
			highlight = <div className="option-on"></div>
			imageCls += " img-option-on"

			if @props.controller?.tags?.COMBO_ACTIVE == 1 and entity.tags.COMBO == 1
				imageCls += " combo"

			if entity.tags.POWERED_UP == 1
				imageCls += " img-option-on combo"

		if entity.tags.TRANSFORMED_FROM_CARD
			tranformedEffect = <div className="transformed-from-card"></div>

		@updateDimensions()

		return  <div key={'card' + entity.id} className={cls} style={@props.style}>
					<div className={highlightCls}>
						<img src={cardArt} className={imageCls} />
						<img src={frame} className="frame"/>
						{rarityImg}
						{nameBanner}
						{nameText}
						{cardText}
						{legendaryFrame}
						{highlight}
						{tranformedEffect}
						{race}
						{stats}
						{cost}
					</div>
				</div>


	updateDimensions: ->
		setTimeout () =>
			domNode = ReactDOM.findDOMNode(this)
			if domNode
				dimensions = @dimensions = domNode.getBoundingClientRect()
				@centerX = dimensions.left + dimensions.width / 2
				@centerY = dimensions.top + dimensions.height / 2
		, 0

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

module.exports = CardInHand
