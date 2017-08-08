React = require 'react'
{ Textfit } = require('react-textfit');

class CardNameBanner extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return <img src={'scripts/static/images/card/name-banner-' + originalCard.type.toLowerCase() + '.png'} className="name-banner" />

module.exports = CardNameBanner
