React = require 'react'
Card = require './card'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'
{subscribe} = require '../../../../subscription'

class Discover extends React.Component

	render: ->
		return null unless (@props.discoverAction and @props.discoverController.id == @props.entity.id)

		console.log 'rendering discover', @props.discoverAction
		hidden = @props.isHidden
		cards = @props.discoverAction.choices.slice(0, 3).map (entity) =>
			#console.log 'is card discarded', @props.mulligan.indexOf(entity.id) != -1, entity, @props.mulligan
			<Card entity={entity} key={entity.id} isHidden={hidden} static={true}/>

		return  <div className="discover-container">
					<div className="discover">
						{cards}
					</div>
				</div>

module.exports = Discover
