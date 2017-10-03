React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require("react-tooltip")

CardArt = require('./card-art')
CardCost = require('./card-cost')
CardFrame = require('./card-frame')
CardName = require('./card-name')
CardText = require('./card-text')
CardRace = require('./card-race')
CardRarity = require('./card-rarity')
CardStats = require('./card-stats')
CardNameBanner = require('./card-name-banner')
CardTooltip = require('../card-tooltip')


class RenderedCard extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		@entityRefId = "" + entity.id
		@tooltipRefId = 'tooltip' + @entityRefId

		if !entity.cardID or @props.isHidden
			return <div key={'card' + entity.id} className="game-card rendered-card" style={@props.style}>
				<div className="art card--unknown"></div>
			</div>

		originalCard = cardUtils?.getCard(entity.cardID)

		cls = 'game-card rendered-card visible'
		if originalCard.type is 'Minion'
			cls += ' minion'
			if originalCard.rarity?.toLowerCase() is 'legendary'
				legendaryFrame = <img src={'scripts/static/images/card/legendary-minion.png'} className="legendary-frame"/>
		else if originalCard.type is 'Spell'
			cls += ' spell'
			if originalCard.rarity?.toLowerCase() is 'legendary'
				legendaryFrame = <img src={'scripts/static/images/card/legendary-spell.png'} className="legendary-frame"/>
		else if originalCard.type is 'Weapon'
			cls += ' weapon'

		if @props.className
			cls += " " + @props.className

		imageCls = "art "
		highlightCls = ''
		if entity.highlighted
			highlightCls += " option-on frame-highlight"

			if @props.controller?.tags?.COMBO_ACTIVE == 1 and entity.tags.COMBO == 1
				highlightCls += " combo"

			if entity.tags.POWERED_UP == 1
				highlightCls += " combo"

		if entity.tags.TRANSFORMED_FROM_CARD
			tranformedEffect = <div className="transformed-from-card"></div>

		@updateDimensions()

		return  <div key={'card' + entity.id} className={cls} style={@props.style} data-tip data-for={entity.id} data-place="right" data-effect="solid" data-delay-show="10" data-class="card-tooltip rendered-card-tooltip">
					<div className={highlightCls}>
						<CardArt cardUtils={cardUtils} entity={entity} />
						<CardFrame cardUtils={cardUtils} entity={entity} conf={conf} />
						<CardRarity cardUtils={cardUtils} entity={entity} />
						<CardNameBanner cardUtils={cardUtils} entity={entity} />
						<CardName cardUtils={cardUtils} entity={entity} />
						<CardText cardUtils={cardUtils} entity={entity} />
						{legendaryFrame}
						{tranformedEffect}
						<CardRace cardUtils={cardUtils} entity={entity} />
						<CardStats cardUtils={cardUtils} entity={entity} />
						<CardCost cardUtils={cardUtils} entity={entity} />
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

module.exports = RenderedCard
