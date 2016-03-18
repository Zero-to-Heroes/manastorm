React = require 'react'
ReactDOM = require 'react-dom'
{subscribe} = require '../../../../subscription'

class Card extends React.Component
	componentDidMount: ->
		tagEvents = 'tag-changed:ATK tag-changed:HEALTH tag-changed:DAMAGE'

		# Discover action creates a null entity here(?)
		if !@props.static
			subscribe @props.entity, tagEvents, =>
				@forceUpdate()

	render: ->
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{@props.entity.cardID}.png"



		if @props.entity.cardID && !@props.isHidden
			style =
				backgroundImage: "url(#{art})"
			cls = "game-card"

			# Cost update 
			if @props.cost
				costCls = "card-cost"
				originalCard = @props.cardUtils.getCard(@props.entity.cardID)
				originalCost = originalCard.cost
				if @props.entity.tags.COST < originalCost
					costCls += " lower-cost"
				else if @props.entity.tags.COST > originalCost
					costCls += " higher-cost"
				cost = <div className={costCls}>{@props.entity.tags.COST}</div>
		else
			style = {}
			cls = "game-card card--unknown"

		if @props.entity.tags.TAUNT
			cls += " card--taunt"

		if @props.className
			cls += " " + @props.className

		if @props.isDiscarded
			cls += " discarded"

		if @props.entity.tags.DIVINE_SHIELD
			overlay = <div className="overlay divine-shield"></div>

		if @props.entity.tags.SILENCED
			overlay = <div className="overlay silenced"></div>

		if @props.entity.tags.FROZEN
			overlay = <div className="overlay frozen"></div>

		if @props.entity.tags.STEALTH
			overlay = <div className="overlay stealth"></div>

		if @props.stats
			healthClass = "card__stats__health"
			if @props.entity.tags.DAMAGE > 0
				healthClass += " damaged"
			stats = <div className="card__stats">
				<div className="card__stats__attack">{@props.entity.tags.ATK or 0}</div>
				<div className={healthClass}>{@props.entity.tags.HEALTH - (@props.entity.tags.DAMAGE or 0)}</div>
			</div>


		@props.entity.damageTaken = @props.entity.damageTaken or 0
		# console.log @props.entity.cardID, @props.entity

		# Can attack
		if @props.entity.highlighted
			cls += " option-on"

		# Exhausted
		if @props.entity.tags.EXHAUSTED == 1 and @props.entity.tags.JUST_PLAYED == 1
			exhausted = <div className="exhausted"></div>

		if @props.entity.tags.DAMAGE - @props.entity.damageTaken > 0
			damage = <span className="damage">{-(@props.entity.tags.DAMAGE - @props.entity.damageTaken)}</span>

		

		# Don't use tooltips if we don't know what card it is - or shouldn't know
		if @props.entity.cardID && !@props.isHidden
			link = '<img src="' + art + '">';
			return <div className={cls} style={style} data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip">
				{overlay}
				{damage}
				{exhausted}
				{stats}
				{cost}
			</div>

		else
			return <div className={cls} style={style}>
				{overlay}
				{damage}
				{exhausted}
				{stats}
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
			dimensions = domNode.getBoundingClientRect()
			@centerX = dimensions.left + dimensions.width / 2
			@centerY = dimensions.top + dimensions.height / 2
		#console.log @centerX, @centerY, dimensions, domNode

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

module.exports = Card
