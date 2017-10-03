React = require 'react'

class WeaponVisual extends React.Component

	render: ->
		replay = @props.replay
		cardUtils = @props.cardUtils
		entity = @props.entity
		originalCard = cardUtils?.getCard(entity.cardID)

		if entity.tags.CONTROLLER != replay.getActivePlayer()?.tags?.PLAYER_ID
			return <img src="scripts/static/images/weapon_sheathed.png" className="visual" />

		return <img src="scripts/static/images/weapon_unsheathed.png" className="visual" />

module.exports = WeaponVisual