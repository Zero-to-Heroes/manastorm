React = require 'react'

class CardNameBanner extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return <img src={'http://static.zerotoheroes.com/hearthstone/asset/manastorm/card/name-banner-' + originalCard.type.toLowerCase() + '.png'} className="name-banner" />

module.exports = CardNameBanner
