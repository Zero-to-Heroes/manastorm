React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")

CardArt = require('./card-art')
CardFrameOnBoard = require('./card-frame-on-board')
CardStats = require('./card-stats')
CardEffect = require('./card-effect')
CardOverlay = require('./card-overlay')
CardExhausted = require('./card-exhausted')
CardDamageTaken = require('./card-damage-taken')
CardHealingReceived = require('./card-healing-received')
CardTooltip = require('../card-tooltip')


class CardOnBoard extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		@entityRefId = "" + entity.id
		@tooltipRefId = 'tooltip' + @entityRefId

		if !entity.cardID or @props.isHidden
			console.error "trying to render a card without card ID", entity
			return null

		originalCard = cardUtils?.getCard(entity.cardID)

		if originalCard.type isnt 'Minion'
			console.error "trying to render a card that isn't a minion", originalCard
			return null

		cls = 'game-card rendered-card minion'
		if originalCard.rarity?.toLowerCase() is 'legendary'
			legendaryFrame = <img src={'scripts/static/images/card/legendary-minion.png'} className="legendary-frame"/>

		if @props.className
			cls += " " + @props.className

		imageCls = "art "
		highlightCls = 'main '
		if entity.highlighted
			highlightCls += " option-on frame-highlight"
			highlight = <div className="option-on"></div>
			imageCls += " img-option-on"

		entity.damageTaken = entity.damageTaken or 0
		
		@updateDimensions()

		return  <div key={'card' + entity.id} className={cls} style={@props.style} data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="10" data-class="card-tooltip rendered-card-tooltip">
					<div className={highlightCls}>
						<CardArt cardUtils={cardUtils} entity={entity} />
						<CardFrameOnBoard cardUtils={cardUtils} entity={entity} conf={conf} />
						{legendaryFrame}
						{highlight}
						<CardEffect cardUtils={cardUtils} entity={entity} />
						<CardOverlay cardUtils={cardUtils} entity={entity} />
						<CardStats cardUtils={cardUtils} entity={entity} />
						<CardExhausted cardUtils={cardUtils} entity={entity} />
						<CardDamageTaken cardUtils={cardUtils} entity={entity} />
						<CardHealingReceived cardUtils={cardUtils} entity={entity} />
					</div>
					<ReactTooltip id={@entityRefId} >
					    <CardTooltip isInfoConcealed={@props.isInfoConcealed} entity={entity} key={@props.entity.id} isHidden={@props.hidden} cost={true} cardUtils={cardUtils} controller={@props.controller} style={@props.style} conf={@props.conf} />
					</ReactTooltip>
				</div>


	updateDimensions: ->
		setTimeout () =>
			domNode = ReactDOM.findDOMNode(this)
			if domNode
				dimensions = @dimensions = domNode.getBoundingClientRect()
				@centerX = dimensions.left + dimensions.width / 2
				@centerY = dimensions.top + dimensions.height / 2
		, 20

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

module.exports = CardOnBoard
