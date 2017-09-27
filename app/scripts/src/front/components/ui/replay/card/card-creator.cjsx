React = require 'react'

class CardCreator extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.tags?.CREATOR

		cardName = cardUtils.getCard(entity.replay.entities[entity.tags.CREATOR].cardID).name

		return <div className="created-by">Created by <span className="card-name">{cardName}</span></div>

module.exports = CardCreator
