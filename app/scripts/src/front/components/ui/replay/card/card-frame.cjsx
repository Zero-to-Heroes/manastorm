React = require 'react'

class CardFrame extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		conf = @props.conf

		originalCard = cardUtils?.getCard(entity.cardID)

		cls = 'game-card rendered-card visible'

		if originalCard.type is 'Minion'
			cls += ' minion'
			if entity.tags.PREMIUM is 1 and !conf?.noGolden
				frame = 'inhand_minion_premium.png'
			else
				frame = 'frame-minion-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Spell'
			cls += ' spell'
			if entity.tags.PREMIUM is 1 and !conf?.noGolden
				frame = 'inhand_spell_premium.png'
			else
				frame = 'frame-spell-' + originalCard.playerClass?.toLowerCase() + '.png'
		else if originalCard.type is 'Weapon'
			cls += ' weapon'
			if entity.tags.PREMIUM is 1 and !conf?.noGolden
				frame = 'inhand_weapon_premium.png'
			else
				frame = 'frame-weapon-' + originalCard.playerClass?.toLowerCase() + '.png'

		frame = 'scripts/static/images/card/' + frame

		return <img src={frame} className="frame"/>

module.exports = CardFrame