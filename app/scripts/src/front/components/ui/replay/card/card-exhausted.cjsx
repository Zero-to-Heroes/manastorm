React = require 'react'

class CardExhausted extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.tags

		originalCard = cardUtils?.getCard(entity.cardID)

		if entity.tags.EXHAUSTED == 1 and entity.tags.JUST_PLAYED == 1
			return <div className="exhausted"></div>
		else 
			return null

module.exports = CardExhausted
