React = require 'react'

class CardArt extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		cardArt = "http://static.zerotoheroes.com/hearthstone/cardart/256x/#{entity.cardID}.jpg"
		imageCls = "art "

		return <img src={cardArt} className={imageCls} />

module.exports = CardArt
