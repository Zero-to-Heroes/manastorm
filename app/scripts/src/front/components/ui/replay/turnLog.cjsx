React = require 'react'
ReactDOM = require 'react-dom'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
$ = require 'jquery'
require 'jquery.scrollTo'
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

	render: ->
		return null unless @props.show

		return 	<div className="turn-log background-white">
					<div className="log-container">
						{@logs}
					</div>
				</div>


	buildActionLog: (action) ->
		# Starting to structure things a bit
		if action.actionType == 'secret-revealed'
			card = action.data['cardID']
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

			newLog = '<span><span class="secret-revealed">\tSecret revealed! </span>' + cardLink + '</span>'
			log = <ActionDisplayLog newLog={newLog} />

			@replay.notifyNewLog log

			return log

		else
			card = if action?.data then action.data['cardID'] else ''

			owner = action.owner.name 
			if !owner
				ownerCard = @replay.entities[action.owner]
				owner = @replay.buildCardLink(@replay.cardUtils.getCard(ownerCard.cardID))
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

			# http://stackoverflow.com/questions/30495062/how-can-i-scroll-a-div-to-be-visible-in-reactjs
			log = <ActionDisplayLog newLog={newLog} />

			@replay.notifyNewLog log

			return log

	buildTurnLog: (turn) ->
		# console.log 'building turn log', turn
		if turn
			if turn.turn is 'Mulligan'
				log = <p className="turn" key={@logIndex++}>Mulligan</p>
			else 
				log = <p className="turn" key={@logIndex++}>
						<TurnDisplayLog turn={turn} active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} />
					</p>

		@replay.notifyNewLog log

		return log


TurnDisplayLog = React.createClass
	componentDidMount: ->
		@index = @logIndex++
		node = ReactDOM.findDOMNode(this)
		$(node).parent().scrollTo("max")
		
	render: ->
		if @props.active
			return <span key={@index}>
				{'Turn ' + Math.ceil(@props.turn.turn / 2) + ' - '}
				<PlayerNameDisplayLog active={true} name={@props.name} />
			</span>
		else
			return <span key={@index}>
				{'Turn ' + Math.ceil(@props.turn.turn / 2) + 'o - '}
				<PlayerNameDisplayLog active={false} name={@props.name} />
			</span>

PlayerNameDisplayLog = React.createClass
	componentDidMount: ->
		@index = @logIndex++
		node = ReactDOM.findDOMNode(this)
		$(node).parent().scrollTo("max")
	
	render: ->
		if @props.active 
			return <span className="main-player" key={@index}>{@props.name}</span>
		else
			return <span className="opponent" key={@index}>{@props.name}</span>


ActionDisplayLog = React.createClass
	componentDidMount: ->
		@index = @logIndex++
		node = ReactDOM.findDOMNode(this)
		$(node).parent().scrollTo("max")

	render: ->
		return <p className="action" key={@index} dangerouslySetInnerHTML={{__html: @props.newLog}}></p>

	ensureVisible: ->

		console.log 'node position'

module.exports = TurnLog
