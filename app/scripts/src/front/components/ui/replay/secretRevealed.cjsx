React = require 'react'
Card = require './card'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'
{subscribe} = require '../../../../subscription'

class SecretRevealed extends React.Component

	render: ->
		entity = @props.entity
		return null unless entity

		cardUtils = @props.replay.cardUtils
		
		secretClass = "secret-splash-container "
		switch entity.tags.CLASS
			when 3
				secretClass += "hunter"
			when 4
				secretClass += "mage"
			when 5
				secretClass += "paladin"

		# console.log 'rendering secret', @props.entity

		return 	<div className={secretClass}>
					<Card entity={entity} key={'secret' + entity.id} ref={'secret' + entity.id} cardUtils={cardUtils}/>
					<div className="secret-splash">
						<div className="splash" />
						<div className="banner" />
						<div className="text">Secret!</div>
					</div>
				</div>



module.exports = SecretRevealed
