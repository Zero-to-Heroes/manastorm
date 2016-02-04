React = require 'react'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

TurnLog = React.createClass

	componentDidMount: ->
		@subs = new SubscriptionList

		@replay = @props.replay

		@logs = []
		@logIndex = 0

		@subs.add @replay, 'new-action', (action) =>
			newLog = @buildActionLog action
			@logs.push newLog
			@forceUpdate()

		@subs.add @replay, 'new-turn', (turn) =>
			newLog = @buildTurnLog turn
			@logs.push newLog
			@forceUpdate()

		@subs.add @replay, 'reset',  =>
			@logs = []
			@forceUpdate()

		@replay.forceReemit()

		@logHtml = ''

		console.log 'component mounted'

	render: ->
		return null unless @props.show

		return 	<div className="turn-log background-white">
				<div className="log-container">
					{@logs}
				</div>
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

		return <p className="action" key={@logIndex++} dangerouslySetInnerHTML={{__html: newLog}}></p>

	buildTurnLog: (turn) ->
		console.log 'building turn log', turn
		if turn
			if turn.turn is 'Mulligan'
				return <p className="turn" key={@logIndex++}>Mulligan</p>
			else 
				return <p className="turn" key={@logIndex++}>
						<TurnDisplayLog turn={turn} active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} />
					</p>

TurnDisplayLog = React.createClass
	render: ->
		if @props.active
			return <span>
				{'Turn ' + Math.ceil(@props.turn.turn / 2) + ' - '}
				<PlayerNameDisplayLog active={true} name={@props.name} />
			</span>
		else
			return <span>
				{'Turn ' + Math.ceil(@props.turn.turn / 2) + 'o - '}
				<PlayerNameDisplayLog active={false} name={@props.name} />
			</span>

PlayerNameDisplayLog = React.createClass
	render: ->
		if @props.active 
			return <span className="main-player">{@props.name}</span>
		else
			return <span className="opponent">{@props.name}</span>


module.exports = TurnLog
