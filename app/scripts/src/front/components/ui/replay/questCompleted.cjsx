React = require 'react'
Card = require './card'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

class QuestCompleted extends React.Component

	render: ->
		entity = @props.entity
		return null unless entity

		cardUtils = @props.replay.cardUtils		

		# console.log 'rendering secret', @props.entity

		return 	<div className="quest-completed-container">
					<Card entity={entity} key={'questCompleted' + entity.id} ref={'secret' + entity.id} cardUtils={cardUtils}/>
				</div>



module.exports = QuestCompleted
