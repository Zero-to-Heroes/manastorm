React = require 'react'

class CardFrameOnBoard extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		originalCard = cardUtils?.getCard(entity.cardID)

		frameCls = 'frame'

		if entity.tags.TAUNT
			frame = 'onboard_minion_taunt.png'
			frameCls += ' taunt'
		else
			frame = 'onboard_minion_frame.png'

		if entity.tags.PREMIUM is 1 and !conf?.noGolden
			frame = 'golden/' + frame

		frame = 'http://static.zerotoheroes.com/hearthstone/asset/manastorm/' + frame

		return <img src={frame} className={frameCls}/>

module.exports = CardFrameOnBoard
