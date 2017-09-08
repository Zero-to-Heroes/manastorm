React = require 'react'

class CardEffect extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		if entity.tags?.POISONOUS
			return <div className="effect poisonous"></div>
		if entity.tags.LIFESTEAL
			return <div className="effect lifesteal"></div>
		else 
			return null

module.exports = CardEffect
