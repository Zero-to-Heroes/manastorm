React = require 'react'

class CardArt extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		cardArt = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/cardart/256x/#{entity.cardID}.jpg"
		imageCls = "art "

		return <img src={cardArt} className={imageCls} />

module.exports = CardArt
