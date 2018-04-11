React = require 'react'
ReactDOM = require 'react-dom'

CardArt = require('./card/card-art')
CardCost = require('./card/card-cost')
CardFrame = require('./card/card-frame')
CardName = require('./card/card-name')
CardText = require('./card/card-text')
CardRace = require('./card/card-race')
CardRarity = require('./card/card-rarity')
CardStats = require('./card/card-stats')
CardEnchantments = require('./card/card-enchantments')
CardCreator = require('./card/card-creator')
CardKeywords = require('./card/card-keywords')
CardNameBanner = require('./card/card-name-banner')

class CardTooltip extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf
		replay = @props.replay

		if !entity.cardID or @props.isHidden
			return <div key={'card' + entity.id} className="game-card rendered-card" style={@props.style}>
				<div className="art card--unknown"></div>
			</div>

		originalCard = cardUtils?.getCard(entity.cardID)

		cls = 'game-card rendered-card visible'
		if originalCard.type is 'Minion'
			cls += ' minion'
			if originalCard.rarity?.toLowerCase() is 'legendary'
				legendaryFrame = <img src={'http://static.zerotoheroes.com/hearthstone/asset/manastorm/card/legendary-minion.png'} className="legendary-frame"/>
		else if originalCard.type is 'Spell'
			cls += ' spell'
			if originalCard.rarity?.toLowerCase() is 'legendary'
				legendaryFrame = <img src={'http://static.zerotoheroes.com/hearthstone/asset/manastorm/card/legendary-spell.png'} className="legendary-frame"/>
		else if originalCard.type is 'Weapon'
			cls += ' weapon'
		else if originalCard.type is 'Hero_power'
			cls += ' hero-power'

		if @props.className
			cls += " " + @props.className

		if entity.tags.TRANSFORMED_FROM_CARD
			tranformedEffect = <div className="transformed-from-card"></div>

		@updateDimensions()

		return  <div className="tooltip-info">
					<div key={'card' + entity.id} className={cls} style={@props.style}>
						<CardArt cardUtils={cardUtils} entity={entity} />
						<CardFrame cardUtils={cardUtils} entity={entity} conf={conf} />
						<CardRarity cardUtils={cardUtils} entity={entity} />
						<CardNameBanner cardUtils={cardUtils} entity={entity} />
						<CardName cardUtils={cardUtils} entity={entity} />
						<CardText cardUtils={cardUtils} entity={entity} replay={replay} />
						{legendaryFrame}
						{tranformedEffect}
						<CardRace cardUtils={cardUtils} entity={entity} />
						<CardStats cardUtils={cardUtils} entity={entity} />
						<CardCost cardUtils={cardUtils} entity={entity} />
						<div className="supplementary-info">
							<CardEnchantments cardUtils={cardUtils} entity={entity} />
							<CardCreator cardUtils={cardUtils} entity={entity} />
						</div>
					</div>
					<CardKeywords cardUtils={cardUtils} entity={entity} />
				</div>


	updateDimensions: ->
		setTimeout () =>
			tooltipNode = ReactDOM.findDOMNode(this)

			return null unless tooltipNode

			# Get the enclosing replay element
			root = document.getElementById('externalPlayer')
			tooltipNode.style.width = 0.66 * root.offsetWidth + 'px'
		, 0

module.exports = CardTooltip
