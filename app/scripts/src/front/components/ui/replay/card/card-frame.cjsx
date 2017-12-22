React = require 'react'

class CardFrame extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		originalCard = cardUtils?.getCard(entity.cardID)
		premium = entity.tags?.PREMIUM

		cls = 'game-card rendered-card visible'

		console.log 'building frame for', entity.cardID, originalCard.name, originalCard, entity, conf

		if originalCard.type is 'Minion'
			cls += ' minion'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-minion-premium.png'
			else
				frame = 'frame-minion-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Spell'
			cls += ' spell'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-spell-premium.png'
			else
				frame = 'frame-spell-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Weapon'
			cls += ' weapon'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-weapon-premium.png'
			else
				frame = 'frame-weapon-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Hero_power'
			cls += ' hero-power'
			frame = 'frame-hero-power.png'
		else if originalCard.type is 'Hero'
			cls += ' hero'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-hero-premium.png'
			else
				frame = 'frame-hero-' + originalCard.playerClass?.toLowerCase() + '.png'

		frame = 'https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/manastorm/images/card/' + frame

		return <img src={frame} className="frame"/>

module.exports = CardFrame
