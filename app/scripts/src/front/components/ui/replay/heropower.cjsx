React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")

Secret = require './Secret'
Health = require './health'
Armor = require './armor'

Card = require './card'
CardArt = require './card/card-art'
CardCost = require './card/card-cost'
HeroPowerTooltip = require './card/hero-power-tooltip'

class HeroPower extends React.Component

	render: ->
		return null unless @props.entity

		entity = @props.entity
		cardUtils = @props.cardUtils
		originalCard = cardUtils.getCard(@props.entity.cardID)

		art = <CardArt cardUtils={cardUtils} entity={entity} />
		heroPowerVisual = <img src="scripts/static/images/hero_power.png" className="visual" />
		cost = <CardCost cardUtils={cardUtils} entity={entity} />

		if @props.entity.tags.EXHAUSTED
			art = <img src="scripts/static/images/hero_power_exhausted.png" className="exhausted" />
			heroPowerVisual = null
			cost = null

		cls = "power"
		if @props.entity.highlighted
			# console.log '\thighlighting', @props.entity.cardID, @props.entity
			cls += " option-on"

		@updateDimensions()

		# console.log '\theropower rendered'
		return 	<div className="power-container" data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="10" data-class="card-tooltip rendered-card-tooltip">
					<div className={cls}>
						{art}
						{heroPowerVisual}
						{cost}
					</div>
					<ReactTooltip id={"" + entity.id} >
					    <HeroPowerTooltip isInfoConcealed={@props.isInfoConcealed} entity={entity} key={entity.id} isHidden={@props.hidden} cost={true} cardUtils={cardUtils} replay={@props.replay} controller={@props.controller} style={@props.style} conf={@props.conf} />
					</ReactTooltip>
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

module.exports = HeroPower
