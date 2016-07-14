React = require 'react'
ReactDOM = require 'react-dom'
{subscribe} = require '../../../../subscription'

class Card extends React.Component
	componentDidMount: ->
		# tagEvents = 'tag-changed:ATK tag-changed:HEALTH tag-changed:DAMAGE'

		# Discover action creates a null entity here(?)
		# if !@props.static
		# 	subscribe @props.entity, tagEvents, =>
		# 		@forceUpdate()

	render: ->
		console.log 'rendering card'
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{@props.entity.cardID}.png"

		imageCls = "art"
		if @props.entity.cardID && !@props.isHidden
			originalCard = @props.cardUtils?.getCard(@props.entity.cardID)
			# Keep both the img (for hand) and background (for the rest)
			imgSrc = art
			style =
				backgroundImage: "url(#{art})"
			cls = "game-card visible"

			# Cost update 
			# We don't have the data for the cards in our opponent's hand
			if @props.cost and !@props.isInfoConcealed
				# console.log 'showing card cost', @props.entity.cardID, @props.entity, !@props.isInfoConcealed
				costCls = "card-cost"
				console.log 'getting card cost from', originalCard, @props.entity
				originalCost = originalCard.cost
				tagCost = @props.entity.tags.COST || originalCost
				if tagCost < originalCost
					costCls += " lower-cost"
				else if tagCost > originalCost
					costCls += " higher-cost"
				cost = <div className={costCls}><span>{tagCost or 0}</span></div>
		else
			style = {}
			cls = "game-card"
			imgSrc = "images/cardback.png"
			imageCls += " card--unknown"

		frameCls = "frame minion"
		legendaryCls = ""

		# console.log 'rendering card', @props.entity.cardID, @props.entity, @props.isInfoConcealed

		if originalCard?.rarity is 'Legendary'
			legendaryCls = " legendary"

		if @props.entity.tags.TAUNT
			frameCls += " card--taunt"

		if @props.entity.tags.DEATHRATTLE
			effect = <div className="effect deathrattle"></div>
		if @props.entity.tags.INSPIRE
			effect = <div className="effect inspire"></div>
		if @props.entity.tags.POISONOUS
			effect = <div className="effect poisonous"></div>
		if @props.entity.tags.TRIGGER
			effect = <div className="effect trigger"></div>

		if @props.className
			cls += " " + @props.className

		if @props.isDiscarded
			cls += " discarded"

		if @props.entity.tags.DIVINE_SHIELD
			divineShield = <div className="overlay divine-shield"></div>

		if @props.entity.tags.SILENCED
			overlay = <div className="overlay silenced"></div>

		if @props.entity.tags.FROZEN
			overlay = <div className="overlay frozen"></div>

		if @props.entity.tags.STEALTH
			overlay = <div className="overlay stealth"></div>

		if @props.entity.tags.WINDFURY
			windfury = <div className="overlay windfury"></div>

		# if @props.stats
		healthClass = "card__stats__health"
		if @props.entity.tags.DAMAGE > 0
			healthClass += " damaged"

		atkCls = "card__stats__attack"
		if originalCard and (originalCard.attack or originalCard.health) and !@props.isInfoConcealed
			originalAtk = originalCard.attack
			tagAtk = @props.entity.tags.ATK || originalAtk
			if tagAtk > originalAtk
				atkCls += " buff"
			else if tagAtk < originalAtk
				atkCls += " debuff"

			originalHealth = originalCard.health
			tagHealth = @props.entity.tags.HEALTH || originalHealth
			if tagHealth > originalHealth
				healthClass += " buff"

			tagDurability = @props.entity.tags.DURABILITY || originalCard.durability
			stats = <div className="card__stats">
				<div className={atkCls}><span>{tagAtk or 0}</span></div>
				<div className={healthClass}><span>{(tagHealth or tagDurability) - (@props.entity.tags.DAMAGE or 0)}</span></div>
			</div>


		@props.entity.damageTaken = @props.entity.damageTaken or 0
		# console.log @props.entity.cardID, @props.entity

		# Can attack
		if @props.entity.highlighted
			highlight = <div className="option-on"></div>
			imageCls += " img-option-on"

			if @props.controller?.tags?.COMBO_ACTIVE == 1 and @props.entity.tags.COMBO == 1
				imageCls += " combo"

		if @props.entity.tags.POWERED_UP == 1
			imageCls += " img-option-on combo"
			# cls += " option-on"

		# Exhausted
		if @props.entity.tags.EXHAUSTED == 1 and @props.entity.tags.JUST_PLAYED == 1
			exhausted = <div className="exhausted"></div>

		if @props.entity.tags.DAMAGE - @props.entity.damageTaken > 0
			damage = <span className="damage"><span>{-(@props.entity.tags.DAMAGE - @props.entity.damageTaken)}</span></span>

		console.log '\tcard rendered'

		# Don't use tooltips if we don't know what card it is - or shouldn't know
		if @props.entity.cardID && !@props.isHidden
			link = '<img src="' + art + '">';
			return <div className={cls} style={@props.style} data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip">
				<div className={imageCls} style={style}></div>
				<img src={imgSrc} className={imageCls}></img>
				<div className={frameCls}></div>
				<div className={legendaryCls}></div>
				{highlight}
				{effect}
				{windfury}
				{overlay}
				{damage}
				{exhausted}
				{stats}
				{divineShield}
				{cost}
			</div>

		else
			return <div className={cls} style={@props.style}>
				<div className={imageCls} style={style}></div>
				<img src={imgSrc} className={imageCls} style={style}></img>
				<div className={frameCls}></div>
				<div className={legendaryCls}></div>
				{highlight}
				{effect}
				{windfury}
				{overlay}
				{damage}
				{exhausted}
				{stats}
				{divineShield}
			</div>

	# cleanTemporaryState: ->
	# 	# console.log 'cleaning temp state'
	# 	@props.entity.damageTaken = @props.entity.tags.DAMAGE or 0
	# 	@props.entity.highlighted = false

	# reset: ->
	# 	console.log 'resetting card'
	# 	@props.entity.damageTaken = 0
	# 	@props.entity.highlighted = false

	# highlightOption: ->
	# 	@props.entity.highlighted = true
	# 	console.log 'highlighting option', @props.entity.cardID, @props.entity, @props.entity.highlighted

	componentDidUpdate: ->
		domNode = ReactDOM.findDOMNode(this)
		if domNode
			#console.log 'updating card dimensions'
			dimensions = @dimensions = domNode.getBoundingClientRect()
			@centerX = dimensions.left + dimensions.width / 2
			@centerY = dimensions.top + dimensions.height / 2
		#console.log @centerX, @centerY, dimensions, domNode

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

module.exports = Card
