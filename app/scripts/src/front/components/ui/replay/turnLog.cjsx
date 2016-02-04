React = require 'react'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

TurnLog = React.createClass

	componentDidMount: ->
		@subs = new SubscriptionList

		@replay = @props.replay

		@subs.add @replay, 'new-log', (action) =>
			#newLog = @buildActionLog action
			#@logHtml += newLog + '<br/>'
			#@forceUpdate()

		@logHtml = ''

	render: ->
		return null #unless @props.show

		return 	<div className="turn-log background-white">
				<p dangerouslySetInnerHTML={{__html: @logHtml}}></p>
			</div>

	buildActionLog: (action) ->
		card = if action?.data then action.data['cardID'] else ''

		owner = action.owner.name 
		if !owner
			ownerCard = @entities[action.owner]
			owner = @replay.buildCardLink(@replay.getCard(ownerCard.cardID))
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
		if action.secret
			if cardLink?.length > 0 and action.publicSecret
				#console.log 'action', action
				cardLink += ' -> Secret'
			else
				cardLink = 'Secret'
		creator = ''
		if action.creator
			creator = @replay.buildCardLink(@replay.cardUtils.getCard(action.creator.cardID)) + ': '
		newLog = owner + action.type + creator + cardLink

		if action.target
			target = @replay.entities[action.target]
			newLog += ' -> ' + @replay.buildCardLink(@replay.cardUtils.getCard(target.cardID))

		newLog

module.exports = TurnLog
