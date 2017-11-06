React = require 'react'
ReactDOM = require 'react-dom'

CardArt = require('./card-art')
CardCost = require('./card-cost')
CardFrame = require('./card-frame')
CardName = require('./card-name')
CardText = require('./card-text')
CardRace = require('./card-race')
CardRarity = require('./card-rarity')
CardStats = require('./card-stats')
CardNameBanner = require('./card-name-banner')

class WeaponTooltip extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		originalCard = cardUtils?.getCard(entity?.cardID)

		return null unless originalCard

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
						<CardArt cardUtils={cardUtils} entity={entity} />
						<CardFrame cardUtils={cardUtils} entity={entity} conf={conf} />
						<CardRarity cardUtils={cardUtils} entity={entity} />
						<CardNameBanner cardUtils={cardUtils} entity={entity} />
						<CardName cardUtils={cardUtils} entity={entity} />
						<CardText cardUtils={cardUtils} entity={entity} replay={@props.replay} />
						{legendaryFrame}
						{highlight}
						{tranformedEffect}
						<CardRace cardUtils={cardUtils} entity={entity} />
						<CardStats cardUtils={cardUtils} entity={entity} />
						<CardCost cardUtils={cardUtils} entity={entity} />
					</div>
				</div>


	updateDimensions: ->
		setTimeout () =>
			tooltipNode = ReactDOM.findDOMNode(this)

			return null unless tooltipNode

			# Get the enclosing replay element
			root = document.getElementById('externalPlayer')
			tooltipNode.style.width = 0.33 * root.offsetWidth + 'px'
		, 0


module.exports = WeaponTooltip
