React = require 'react'

class CardFrame extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		originalCard = cardUtils?.getCard(entity.cardID)
		premium = entity.tags?.PREMIUM

		cls = 'game-card rendered-card visible'

		playerClass = originalCard.playerClass?.toLowerCase()
		# console.log 'building frame for', entity.cardID, originalCard.name, originalCard, entity, playerClass

		#Ysera
		if playerClass is 'dream'
			playerClass = 'hunter'

		if originalCard.type is 'Minion'
			cls += ' minion'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-minion-premium.png'
			else
				frame = 'frame-minion-' + playerClass + '.png'
		else if originalCard.type is 'Spell'
			cls += ' spell'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-spell-premium.png'
			else
				frame = 'frame-spell-' + playerClass + '.png'
		else if originalCard.type is 'Weapon'
			cls += ' weapon'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-weapon-premium.png'
			else
				frame = 'frame-weapon-' + playerClass + '.png'
		else if originalCard.type is 'Hero_power'
			cls += ' hero-power'
			frame = 'frame-hero-power.png'
		else if originalCard.type is 'Hero'
			cls += ' hero'
			if premium is 1 and !conf?.noGolden
				frame = 'frame-hero-premium.png'
			else
				frame = 'frame-hero-' + playerClass + '.png'

		frame = 'http://static.zerotoheroes.com/hearthstone/asset/manastorm/card/' + frame

		return <img src={frame} className="frame"/>

module.exports = CardFrame
