React = require 'react'

class CardEffect extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		console.log 'rendering', entity.cardID, entity

		return null unless entity.tags

		originalCard = cardUtils?.getCard(entity.cardID)

		if entity.tags.POISONOUS
			return <div className="effect poisonous"></div>
		if entity.tags.LIFESTEAL
			return <div className="effect lifesteal"></div>
		if entity.tags.DEATH_RATTLE
			return <div className="effect deathrattle"></div>
		if entity.tags.INSPIRE
			return <div className="effect inspire"></div>
		if entity.tags.TRIGGER
			return <div className="effect trigger"></div>
		else
			return null

module.exports = CardEffect
