React = require 'react'

class CardNameBanner extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return <img src={'https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/manastorm/images/card/name-banner-' + originalCard.type.toLowerCase() + '.png'} className="name-banner" />

module.exports = CardNameBanner
