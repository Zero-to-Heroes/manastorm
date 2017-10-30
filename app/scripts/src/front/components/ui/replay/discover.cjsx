React = require 'react'
RenderedCard = require './card/rendered-card'

class Discover extends React.Component

	render: ->
		return null unless (@props.discoverAction and @props.discoverController.id == @props.entity.id)

		# console.log 'rendering discover', @props.discoverAction
		replay = @props.replay
		hidden = @props.isHidden
		cards = @props.discoverAction.choices.slice(0, @props.discoverAction.choices.length).map (entity) =>
			#console.log 'is card discarded', @props.mulligan.indexOf(entity.id) != -1, entity, @props.mulligan
			#console.log 'discover card', entity
			discovered = if @props.discoverAction.discovered is entity.id then 'picked' else ''
			<RenderedCard className={discovered} entity={entity} replay={replay} key={entity.id} isHidden={hidden} static={true} cardUtils={replay.cardUtils} conf={@props.conf} />

		return  <div className="discover-container">
					<div className="discover">
						{cards}
					</div>
				</div>

module.exports = Discover
