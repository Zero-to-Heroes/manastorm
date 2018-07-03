React = require 'react'
_ = require 'lodash'

RenderedCard = require './card/rendered-card'

class Overdraw extends React.Component

	render: ->
		return null unless @props.isOverdraw

		console.log 'overdraw action', @props.action
		replay = @props.replay

		burntCards = @props.action.data.slice(0, @props.action.data.length).map (entityId) =>
			entity = replay.entities[entityId]
			console.log 'showing burnt card', entity
			<RenderedCard className="burnt" entity={entity} replay={replay} key={entity.id} static={true} cardUtils={replay.cardUtils} conf={@props.conf} />

		return  <div className="overdraw">
					<div className="burnt-cards">
						{burntCards}
					</div>
					<span className="text">Burned cards</span>
				</div>

module.exports = Overdraw
