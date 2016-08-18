React = require 'react'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'
{subscribe} = require '../../../../subscription'

class Fatigue extends React.Component

	render: ->
		# console.log 'rendering endgame?', @props.entity
		# WON, LOST, CONCEDED
		return null unless @props.isFatigue

		return  <div className="fatigue">
					<span className="text">Out of cards! Take {@props.action.damage} damage.</span>
				</div>

module.exports = Fatigue
