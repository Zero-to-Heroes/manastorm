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
			for logLine in newLog
				@logs.push logLine
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
		if action.actionType == 'card-draw'
			log = @buildCardDrawLog action

		else if action.actionType == 'secret-revealed'
			log = @buildSecretRevealedLog action

		else if action.actionType == 'played-card-from-hand'
			log = @buildPlayedCardFromHandLog action

		else if action.actionType == 'played-secret-from-hand'
			log = @buildPlayedSecretFromHandLog action

		else if action.actionType == 'power-damage'
			log = @buildPowerDamageLog action

		else if action.actionType == 'power-target'
			log = @buildPowerTargetLog action

		else if action.actionType == 'attack'
			log = @buildAttackLog action

		else if action.actionType == 'minion-death'
			log = @buildMinionDeathLog action

		else if action.actionType == 'discover'
			log = @buildDiscoverLog action

		else if action.actionType == 'summon-minion'
			log = @buildSummonMinionLog action

		else if action.actionType == 'summon-weapon'
			log = @buildSummonWeaponLog action

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
		return [log]

	buildTurnLog: (turn) ->
		# console.log 'building turn log', turn
		if turn
			if turn.turn is 'Mulligan'
				log = @buildMulliganLog turn
				return log
			else 
				log = <p className="turn" key={@logIndex++}>
						<TurnDisplayLog turn={turn} active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} />
					</p>

				@replay.notifyNewLog log
				return [log]

	

	# ===================
	# Action specific logs
	# ===================
	buildSecretRevealedLog: (action) ->
		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		newLog = '<span><span class="secret-revealed">\tSecret revealed! </span>' + cardLink + '</span>'
		log = <ActionDisplayLog newLog={newLog} />

		@replay.notifyNewLog log

		return [log]

	buildCardDrawLog: (action) ->
		# Don't show hidden information
		if action.owner == @replay.player
			card = if action?.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
		else
			cardLink = '<span> 1 card </span>'

		drawLog = <p key={++@logIndex}>
					<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
					<span> draws </span>
					<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
				</p>

		return drawLog

	buildPlayedCardFromHandLog: (action) ->
		card = if action?.data then action.data['cardID'] else ''
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays </span>
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
			</p>

		return log

	buildPlayedSecretFromHandLog: (action) ->

		if cardLink?.length > 0 and action.publicSecret
			card = if action?.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			link = <span>: </span>
		else

		log = <p key={++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays a </span> 
				<span className="secret-revealed">Secret </span>
				{link}
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
			</p>

		return log

	buildPowerDamageLog: (action) ->
		if !action.sameOwnerAsParent
			card = if action.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			indent = <span className="indented-log">...which </span>

		target = @replay.entities[action.target]['cardID']
		targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))

		log = <p key={++@logIndex}>
			    {indent}
			    {cardLog}
			    <span> deals {action.amount} damage to </span>
			    <SpanDisplayLog newLog={targetLink} />
			</p>

		return log

	buildPowerTargetLog: (action) ->
		if !action.sameOwnerAsParent
			card = if action.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			indent = <span className="indented-log">...and </span>

		target = @replay.entities[action.target]['cardID']
		targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))

		log = <p key={++@logIndex}>
			    {indent}
			    {cardLog}
			    <span> targets </span>
			    <SpanDisplayLog newLog={targetLink} />
			</p>

		return log

	buildAttackLog: (action) ->
		card = if action.data then action.data['cardID'] else ''
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		target = @replay.entities[action.target]['cardID']
		targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))

		log = <p key={++@logIndex}>
			    <SpanDisplayLog newLog={cardLink} />
			    <span> attacks </span>
			    <span dangerouslySetInnerHTML={{__html: targetLink}}></span>
			</p>

		return log

	buildMinionDeathLog: (action) ->
		card = @replay.entities[action.data]['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
			    <SpanDisplayLog newLog={cardLink} />
			    <span> dies </span>
			</p>

	buildDiscoverLog: (action) ->
		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		choicesCards = []
		for choice in action.choices
			choiceCard = choice['cardID']
			choiceCardLink = @replay.buildCardLink(@replay.cardUtils.getCard(choiceCard))
			choicesCards.push <SpanDisplayLog className="discovered-card indented-log" newLog={choiceCardLink} />

		log = <p key={++@logIndex}>
			    <SpanDisplayLog newLog={cardLink} />
			    <span> discovers </span>
			    {choicesCards}
			    <span></span>
			</p>

		return log

	buildSummonMinionLog: (action) ->
		console.log 'buildSummonMinionLog', action
		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			indent = <span className="indented-log">...which</span>
		else
			indent = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
			    {indent}		
			    <span> summons </span> 
			    <SpanDisplayLog newLog={cardLink} />
			</p>

		return log

	buildSummonWeaponLog: (action) ->
		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			indent = <span className="indented-log">...which</span>
		else
			indent = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
			    {indent}
			    <span> equips </span>
			    <SpanDisplayLog newLog={cardLink} />
			</p>

		return log

	# ===================
	# Turn specific log
	# ===================
	buildMulliganLog: (turn) ->
		log = <p className="turn" key={++@logIndex}>Mulligan</p>

		@replay.notifyNewLog log

		logs = [log]
		# Additional data on cards mulliganed
		if turn.playerMulligan?.length > 0
			for mulliganed in turn.playerMulligan
				cardId = @replay.entities[mulliganed].cardID
				console.log 'cardId', cardId
				card = @replay.cardUtils.getCard(cardId)
				console.log 'card', card
				cardLink = @replay.buildCardLink(card)
				cardLog = <p key={++@logIndex}>
							<PlayerNameDisplayLog active={true} name={@replay.player.name} />
							<span> mulligans </span>
							<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
						</p>
				logs.push cardLog

		if turn.opponentMulligan?.length > 0
			cardLog = <p key={++@logIndex}>
				<PlayerNameDisplayLog active={false} name={@replay.opponent.name} /> mulligans {turn.opponentMulligan.length} cards
			</p>
			logs.push cardLog

		return logs


	# ===============
	# Utilities
	# ===============
	playerName: (turn) -> 
		return <PlayerNameDisplayLog active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} />

# ===============
# And DRY obkects
# ===============
TurnDisplayLog = React.createClass
	componentDidMount: ->
		@index = @logIndex++
		node = ReactDOM.findDOMNode(this)
		$(node).parent().parent().scrollTo("max")
		console.log 'mounted TurnDisplayLog', node, $(node), $(node).parent()
		
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
		$(node).parent().parent().scrollTo("max")
	
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
		cls = @props.className
		cls += " action"
		return <p className={cls} key={@index} dangerouslySetInnerHTML={{__html: @props.newLog}}></p>

SpanDisplayLog = React.createClass
	componentDidMount: ->
		@index = ++@logIndex
		node = ReactDOM.findDOMNode(this)
		$(node).parent().parent().scrollTo("max")

	render: ->
		cls = @props.className
		cls += " action"
		return <span className={cls} key={@index} dangerouslySetInnerHTML={{__html: @props.newLog}}></span>


module.exports = TurnLog
