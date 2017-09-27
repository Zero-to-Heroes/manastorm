React = require 'react'

class CardDamageTaken extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.tags

		originalCard = cardUtils?.getCard(entity.cardID)

		if entity.tags.DAMAGE - entity.damageTaken > 0
			return <span className="damage"><span>{-(entity.tags.DAMAGE - entity.damageTaken)}</span></span>
		else 
			return null

module.exports = CardDamageTaken
