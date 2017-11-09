React = require 'react'

class CardOverlay extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.tags

		originalCard = cardUtils?.getCard(entity.cardID)

		if entity.tags.DIVINE_SHIELD
			divineShield = <div className="overlay divine-shield"></div>
		if entity.tags.CANT_BE_DAMAGED
			immune = <div className="overlay immune"></div>
		if entity.tags.SILENCED
			silenced = <div className="overlay silenced"></div>
		if entity.tags.FROZEN
			frozen = <div className="overlay frozen"></div>
		if entity.tags.STEALTH
			stealth = <div className="overlay stealth"></div>
		if entity.tags.CANT_BE_TARGETED_BY_ABILITIES and entity.tags.CANT_BE_TARGETED_BY_HERO_POWERS
			elusive = <div className="overlay elusive"></div>
		if entity.tags.WINDFURY
			windfury = <div className="overlay windfury"></div>

		return <div>
				{silenced}
				{divineShield}
				{immune}
				{frozen}
				{stealth}
				{elusive}
				{windfury}
			</div>

module.exports = CardOverlay
