React = require 'react'
Card = require './card'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'
{subscribe} = require '../../../../subscription'

class SplashReveal extends React.Component

	render: ->
		entity = @props.entity
		return null unless entity

		cardUtils = @props.replay.cardUtils
		
		splashClass = "splash-reveal-container "

		# console.log 'rendering secret', @props.entity

		return 	<div className={splashClass}>
					<Card entity={entity} key={'splash-reveal' + entity.id} ref={'splash-reveal' + entity.id} cardUtils={cardUtils} isInfoConcealed={true} />
				</div>



module.exports = SplashReveal
