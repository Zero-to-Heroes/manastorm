React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")
{subscribe} = require '../../../../subscription'

class Card extends React.Component

	render: ->
		# console.log 'rendering card'
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		cardUtils = @props.cardUtils
		entity = @props.entity

		if entity.cardID
			originalCard = cardUtils?.getCard(entity.cardID)

		premium = ''
		premiumClass = ''
		suffix = '.png'

		imageCls = "art "
		# console.log 'rendering card', entity.cardID, originalCard, entity, originalCard?.set?.toLowerCase()
		if entity.tags.PREMIUM is 1 and originalCard?.goldenImage
			# console.log 'showing golden card', entity, originalCard
			premiumClass = 'golden'
			premium = premiumClass + '/'
			suffix = '.gif'


		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{premium}#{entity.cardID}" + suffix


		# imageCls = "art "
		if entity.cardID && !@props.isHidden
			# Keep both the img (for hand) and background (for the rest)
			imgSrc = art
			style =
				backgroundImage: "url(#{art})"
			cls = "game-card visible"

			# Cost update 
			# We don't have the data for the cards in our opponent's hand
			if @props.cost and !@props.isInfoConcealed
				# console.log 'showing card cost', entity.cardID, entity, !@props.isInfoConcealed
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
		else
			style = {}
			cls = "game-card"
			# imgSrc = "images/cardback.png"
			imageCls += " card--unknown"

		cls += ' ' + premiumClass

		frameCls = "frame minion"
		legendaryCls = ""

		# console.log 'rendering card', entity.cardID, @props.cost, entity.tags.COST, @props.isHidden, entity, @props.isInfoConcealed

		if originalCard?.rarity is 'Legendary'
			legendaryCls = " legendary"

		if entity.tags.TAUNT
			taunt = <div className="taunt"></div>
			# frameCls += " card--taunt"

		if entity.tags.DEATHRATTLE
			effect = <div className="effect deathrattle"></div>
		if entity.tags.INSPIRE
			effect = <div className="effect inspire"></div>
		if entity.tags.POISONOUS
			effect = <div className="effect poisonous"></div>
		if entity.tags.TRIGGER
			effect = <div className="effect trigger"></div>

		if @props.className
			cls += " " + @props.className

		if @props.isDiscarded
			cls += " discarded"

		if entity.tags.DIVINE_SHIELD
			divineShield = <div className="overlay divine-shield"></div>

		if entity.tags.SILENCED
			overlay = <div className="overlay silenced"></div>

		if entity.tags.FROZEN
			overlay = <div className="overlay frozen"></div>

		if entity.tags.STEALTH
			overlay = <div className="overlay stealth"></div>

		if entity.tags.WINDFURY
			windfury = <div className="overlay windfury"></div>

		# if @props.stats
		healthClass = "card__stats__health"
		if entity.tags.DAMAGE > 0
			healthClass += " damaged"

		atkCls = "card__stats__attack"
		if originalCard and (originalCard.attack or originalCard.health) and !@props.isInfoConcealed
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
			stats = <div className="card__stats">
				<div className={atkCls}><span>{tagAtk or 0}</span></div>
				<div className={healthClass}><span>{(tagHealth or tagDurability) - (entity.tags.DAMAGE or 0)}</span></div>
			</div>


		entity.damageTaken = entity.damageTaken or 0
		# console.log entity.cardID, entity

		# Can attack
		highlightCls = ''
		if entity.highlighted
			highlightCls += " option-on frame-highlight"
			highlight = <div className="option-on"></div>
			imageCls += " img-option-on"

			if @props.controller?.tags?.COMBO_ACTIVE == 1 and entity.tags.COMBO == 1
				imageCls += " combo"

			if entity.tags.POWERED_UP == 1
				imageCls += " img-option-on combo"
			# cls += " option-on"

		# Exhausted
		if entity.tags.EXHAUSTED == 1 and entity.tags.JUST_PLAYED == 1
			exhausted = <div className="exhausted"></div>

		if entity.tags.DAMAGE - entity.damageTaken > 0
			damage = <span className="damage"><span>{-(entity.tags.DAMAGE - entity.damageTaken)}</span></span>
		else if entity.tags.DAMAGE - entity.damageTaken < 0
			healing = <span className="healing"><span>{-(entity.tags.DAMAGE - entity.damageTaken)}</span></span>

		if entity.id is 83
			console.log 'rendering', entity.cardID, entity

		enchantments = @buildEnchantments entity
		statuses = @buildStatuses entity
		createdBy = @buildCreator entity

		# Build the card link on hover. It includes the card image + the status alterations		
		enchantmentClass = if enchantments?.length > 0 then 'enchantments' else ''


		
		if originalCard?.set?.toLowerCase() is 'gangs' and !@props.isHidden
			# console.log '\tgangs card'
			imageCls += " quick-fix"
			enchantmentClass += ' quick-fix'

		cardTooltip = 
			<div className="card-container">
				<div className="game-info">
					<img src={art} />
					<div className={enchantmentClass}>
						{enchantments}
					</div>
					{createdBy}
				</div>
				<div className='statuses'>
					<div className="filler"></div>
					{statuses}
				</div>
			</div>

		# frameHighlight = frameCls + " frame-highlight" + legendaryCls

		@updateDimensions()

		# Don't use tooltips if we don't know what card it is - or shouldn't know
		if entity.cardID && !@props.isHidden
			# link = '<img src="' + art + '">';
			return <div key={'card' + entity.id} className={cls} style={@props.style} data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="50" data-class="card-tooltip">
				<div className={highlightCls}>
					{taunt}
					<div className={imageCls} style={style}></div>
					<img src={imgSrc} className={imageCls}></img>
					<div className={frameCls}></div>
					<div className={legendaryCls}></div>
					{highlight}
					{effect}
					{windfury}
					{overlay}
					{damage}
					{healing}
					{exhausted}
					{stats}
					{divineShield}
					{cost}
				</div>
				<ReactTooltip id={"" + entity.id} >
				    {cardTooltip}
				</ReactTooltip>
			</div>

		else
			return <div key={'card' + entity.id} className={cls} style={@props.style}>
				{taunt}
				<div className={imageCls} style={style}></div>
				<img src={imgSrc} className={imageCls} style={style}></img>
				<div className={frameCls}></div>
				<div className={legendaryCls}></div>
				{highlight}
				{effect}
				{windfury}
				{overlay}
				{damage}
				{healing}
				{exhausted}
				{stats}
				{divineShield}
			</div>

	updateDimensions: ->
		setTimeout () =>
			domNode = ReactDOM.findDOMNode(this)
			if domNode
				dimensions = @dimensions = domNode.getBoundingClientRect()
				@centerX = dimensions.left + dimensions.width / 2
				@centerY = dimensions.top + dimensions.height / 2
				# if @props.entity?.id is 14
				# 	console.log 'updating card dimensions', @props.entity?.cardID, @props.entity?.id, dimensions, @centerX, @centerY, @props.entity
		, 0
		#console.log @centerX, @centerY, dimensions, domNode

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

	buildEnchantments: (entity) ->
		cardUtils = @props.cardUtils
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''

		# console.log 'entity in card', entity, entity.getEnchantments
		if entity.getEnchantments?()?.length > 0
			# console.log 'enchantments', entity.cardID, entity, entity.getEnchantments()

			seqNumber = 0

			enchantments = entity.getEnchantments().map (enchant) ->
				enchantor = entity.replay.entities[enchant.tags.CREATOR]
				# console.log 'enchantor', enchantor, entity.replay.entities, enchant.tags.CREATOR, enchant
				enchantCard = cardUtils?.getCard(enchant.cardID)

				if enchantor
					enchantImage = 
						backgroundImage: "url(https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{enchantor.cardID}.png)"
					enchantImageUrl = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{enchantor.cardID}.png"

				<div className="enchantment" key={'enchantment' + entity.id + enchant.cardID + seqNumber++}>
					<h3 className="name">{cardUtils?.localizeName(enchantCard)}</h3>
					<div className="info-container">
						<div className="icon" style={enchantImage}></div>
						<span className="text" dangerouslySetInnerHTML={{__html: cardUtils?.localizeText(enchantCard)}}></span>
					</div>
				</div>

			# enchantmentClass = "enchantments"

		return enchantments

	buildStatuses: (entity) ->
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''

		# The keywords
		keywords = []

		# console.log 'build statuses', entity.cardID, entity, cardUtils?.keywords

		for k,v of entity.tags
			key = 'GLOBAL_KEYWORD_' + k
			# console.log '\t' + key, v
			if v isnt 0 and cardUtils?.keywords[key]
				# console.log '\t\texists'
				name = cardUtils?.localizeKeyword(key)
				text = cardUtils?.localizeKeyword(key + '_TEXT')
				# console.log '\t\texists', name, text
				statusElement = 
					<div className="status" key={'status' + entity.id + key}>
						<h3>{name}</h3>
						<span>{text}</span>
					</div>
				# console.log '\t\tbuild', statusElement
				keywords.push statusElement

		return keywords

	buildCreator: (entity) ->
		if entity.tags.CREATOR
			cardUtils = @props.cardUtils
			cardName = cardUtils?.getCard(entity.replay?.entities[entity.tags.CREATOR]?.cardID)?.name
			if cardName
				createdBy = 
					<div className="created-by">
						Created by <span className="card-name">{cardName}</span>
					</div>
		return createdBy

module.exports = Card
