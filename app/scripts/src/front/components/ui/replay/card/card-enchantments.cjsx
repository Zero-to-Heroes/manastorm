React = require 'react'

class CardEnchantments extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.getEnchantments?()?.length > 0

		originalCard = cardUtils.getCard(entity.cardID)

		seqNumber = 0

		enchantments = entity.getEnchantments().map (enchant) ->
			enchantor = entity.replay.entities[enchant.tags.CREATOR]
			# console.log 'enchantor', enchantor, entity.replay.entities, enchant.tags.CREATOR, enchant
			enchantCard = cardUtils.getCard(enchant.cardID)

			return null unless enchantor

			enchantImageUrl = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/cardart/256x/#{enchantor.cardID}.jpg"

			<div className="enchantment" key={'enchantment' + entity.id + enchant.cardID + seqNumber++}>
				<h3 className="name">{cardUtils.localizeName(enchantCard)}</h3>
				<div className="info-container">
					<img className="icon" src={enchantImageUrl} />
					<img className="ring" src="https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/manastorm/images/enchantment-ring.png" />
					<span className="text" dangerouslySetInnerHTML={{__html: cardUtils.localizeText(enchantCard)}}></span>
				</div>
			</div>

		return <div className="enchantments">
					{enchantments}
				</div>

module.exports = CardEnchantments
