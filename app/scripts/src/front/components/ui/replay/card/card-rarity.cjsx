React = require 'react'

class CardRarity extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return null unless originalCard.rarity and originalCard.rarity isnt 'Free'

		if originalCard.type is 'Minion'
			rarity = 'rarity-minion-' + originalCard.rarity.toLowerCase() + '.png'
		else if originalCard.type is 'Spell'
			rarity = 'rarity-spell-' + originalCard.rarity.toLowerCase() + '.png'
		else if originalCard.type is 'Weapon'
			rarity = 'rarity-weapon-' + originalCard.rarity.toLowerCase() + '.png'
		else if originalCard.type is 'Hero'
			rarity = 'rarity-' + originalCard.rarity.toLowerCase() + '.png'

		return <img src={'https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/manastorm/images/card/' + rarity} className="rarity"/>

module.exports = CardRarity
