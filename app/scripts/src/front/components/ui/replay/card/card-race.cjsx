React = require 'react'

class CardRace extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return null unless originalCard.race

		return <div className="race">
					<img src={'scripts/static/images/card/race-banner.png'} className="race-banner" />
					<p>{originalCard.race.toLowerCase()}</p>
				</div>

module.exports = CardRace
