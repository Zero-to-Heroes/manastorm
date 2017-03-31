React = require 'react'
Card = require './card'
_ = require 'lodash'

class Mulligan extends React.Component

	render: ->
		# console.log 'rendering mulligan?', @props.entity, @props.entity.getHand(), @props.mulligan
		return null unless @props.inMulligan 
		

		# console.log '\tyes'
		hidden = @props.isHidden
		cards = @props.entity.getHand().slice(0, 4).map (entity) =>
			# console.log 'is card discarded', @props.mulligan.indexOf(entity.id) != -1, entity, @props.mulligan
			<Card entity={entity} key={entity.id} isHidden={hidden} isDiscarded={@props.mulligan.indexOf(entity.id) != -1} cardUtils={@props.replay.cardUtils} conf={@props.conf} />

		return <div className="mulligan">
				{cards}
			</div>

module.exports = Mulligan
