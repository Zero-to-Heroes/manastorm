React = require 'react'

class CardCost extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		costCls = "card-cost"

		originalCost = originalCard.cost
		if entity.tags.COST is 0
			tagCost = 0
		else
			tagCost = entity.tags.COST || originalCost

		if tagCost < originalCost
			costCls += " lower-cost"
		else if tagCost > originalCost
			costCls += " higher-cost"

		return <div className={costCls}><span>{tagCost or 0}</span></div>

module.exports = CardCost
