React = require 'react'

class CardOverlay extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.tags

		originalCard = cardUtils?.getCard(entity.cardID)

module.exports = CardOverlay
