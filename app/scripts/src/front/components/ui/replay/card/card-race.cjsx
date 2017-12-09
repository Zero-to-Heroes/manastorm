React = require 'react'

class CardRace extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return null unless originalCard.race

		return <div className="race">
					<img src={'https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/manastorm/images/card/race-banner.png'} className="race-banner" />
					<p>{originalCard.race.toLowerCase()}</p>
				</div>

module.exports = CardRace
