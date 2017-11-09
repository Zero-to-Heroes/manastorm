React = require 'react'

class CardStats extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		return null unless originalCard.attack or originalCard.health or originalCard.durability or originalCard.armor

		healthClass = "card__stats__health"
		atkCls = "card__stats__attack"

		originalAtk = originalCard.attack
		if entity.tags.ATK?
			tagAtk = entity.tags.ATK
		else
			tagAtk = originalAtk
		if tagAtk > originalAtk
			atkCls += " buff"
		else if tagAtk < originalAtk
			atkCls += " debuff"

		originalHealth = originalCard.health
		tagHealth = entity.tags.HEALTH || originalHealth
		if tagHealth > originalHealth
			healthClass += " buff"
		if entity.tags.DAMAGE > 0
			healthClass += " damaged"

		tagDurability = entity.tags.DURABILITY || originalCard.durability
		return <div className="card__stats">
				<div className={atkCls}><span>{tagAtk or 0}</span></div>
				<div className={healthClass}><span>{(tagHealth or tagDurability) - (entity.tags.DAMAGE or 0)}</span></div>
				<div className="card__stats__armor"><span>{(entity.tags.ARMOR)}</span></div>
			</div>

module.exports = CardStats
