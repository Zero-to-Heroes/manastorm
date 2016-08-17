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
		@logIndex = 10000

		# console.log 'mounteeeeeeeeeeeeeeeeeeeeeeeeeed'

		@subs.add @replay, 'new-action', (action) =>
			newLog = @buildActionLog action
			for logLine in newLog
				@logs.push logLine
			# @forceUpdate()

		@subs.add @replay, 'previous-action', (action) =>
			popped = @logs.pop()
			# console.log 'popping last element from game log', popped

		@subs.add @replay, 'new-turn', (turn) =>
			newLog = @buildTurnLog turn
			@logs.push newLog
			# @forceUpdate()

		@subs.add @replay, 'reset',  =>
			@logs = []
			# @forceUpdate()

		@replay.forceReemit()

	render: ->
		return null unless @props.show

		# console.log 'rendering turnLog'

		return 	<div className="turn-log background-white">
					<div className="close" onClick={@props.onClose}></div>
					<div className="log-container" id="turnLog">
						{@logs}
					</div>
				</div>


	buildActionLog: (action) ->
		if action.actionType == 'card-draw'
			log = @buildCardDrawLog action

		if action.actionType == 'card-discard'
			log = @buildCardDiscardLog action

		else if action.actionType == 'overdraw'
			log = @buildOverdrawLog action

		else if action.actionType == 'secret-revealed'
			log = @buildSecretRevealedLog action

		else if action.actionType == 'played-card-from-hand'
			log = @buildPlayedCardFromHandLog action

		else if action.actionType == 'hero-power'
			log = @buildHeroPowerLog action

		else if action.actionType == 'played-secret-from-hand'
			log = @buildPlayedSecretFromHandLog action

		else if action.actionType == 'power-damage'
			log = @buildPowerDamageLog action

		else if action.actionType == 'power-healing'
			log = @buildPowerHealingLog action

		else if action.actionType == 'power-target'
			log = @buildPowerTargetLog action

		else if action.actionType == 'played-card-with-target'
			log = @buildPlayedCardWithTargetLog action

		else if action.actionType == 'trigger-fullentity'
			log = @buildTriggerFullEntityLog action

		else if action.actionType == 'summon-weapon'
			log = @buildSummonWeaponLog action

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

		else if action.actionType == 'trigger-secret-play'
			log = @buildTriggerSecretPlayLog action

		else if action.actionType == 'new-hero-power'
			log = @buildNewHeroPowerLog action

		else if action.actionType == 'fatigue-damage'
			log = @buildFatigueDamageLog action

		else if action.actionType == 'end-game'
			log = @buildEndGameLog action


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
			cardLink = @buildList action.data
			# card = if action?.data then action.data['cardID'] else ''
			# cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
		else if action.data.length == 1
			cardLink = '<span> ' + action.data.length + ' card </span>'
			cardLink = <SpanDisplayLog newLog={cardLink} />
		else
			cardLink = '<span> ' + action.data.length + ' cards </span>'
			cardLink = <SpanDisplayLog newLog={cardLink} />

		# The effect occured as a response to another action, so we need to make that clear
		indent = <span key={++@logIndex}></span>
		if action.mainAction
			indentText = '<span>...and </span>'
			indent = <SpanDisplayLog className="indented-log" newLog={indentText} />
			if action.owner != @replay.getActivePlayer()
				drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
		else
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		drawLog = <p key={++@logIndex}>
					{indent}
					{drawer}
					<span key={++@logIndex}> draws </span>
					{cardLink}
				</p>

		return drawLog

	buildCardDiscardLog: (action) ->
		# Don't show hidden information
		if action.owner == @replay.player
			cardLink = @buildList action.data
		else if action.data.length == 1
			cardLink = '<span> ' + action.data.length + ' card </span>'
			cardLink = <SpanDisplayLog newLog={cardLink} />
		else
			cardLink = '<span> ' + action.data.length + ' cards </span>'
			cardLink = <SpanDisplayLog newLog={cardLink} />

		# The effect occured as a response to another action, so we need to make that clear
		indent = <span key={++@logIndex}></span>
		if action.mainAction
			indentText = '<span>...and </span>'
			indent = <SpanDisplayLog className="indented-log" newLog={indentText} />
			if action.owner != @replay.getActivePlayer()
				drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
		else
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		drawLog = <p key={++@logIndex}>
					{indent}
					{drawer}
					<span key={++@logIndex}> discards </span>
					{cardLink}
				</p>

		return drawLog

	buildOverdrawLog: (action) ->
		if action.owner == @replay.player
			cardLink = @buildList action.data
			# card = if action?.data then action.data['cardID'] else ''
			# cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
		else if action.data.length == 1
			cardLink = '<span> ' + action.data.length + ' card! </span>'
			cardLink = <SpanDisplayLog newLog={cardLink} />
		else
			cardLink = '<span> ' + action.data.length + ' cards! </span>'
			cardLink = <SpanDisplayLog newLog={cardLink} />

		# The effect occured as a response to another action, so we need to make that clear
		indent = <span></span>
		if action.mainAction
			indentText = '<span>...and </span>'
			indent = <SpanDisplayLog className="indented-log" newLog={indentText} />
			if action.owner != @replay.getActivePlayer()
				drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
		else
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		drawLog = <p key={++@logIndex}>
					{indent}
					{drawer}
					<span className="overdraw" key={++@logIndex}> overdraws </span>
					{cardLink}
				</p>

		return drawLog

	buildPlayedCardFromHandLog: (action) ->
		card = action.data['cardID']
		# console.log 'buildPlayedCardFromHandLog', action, card
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays </span>
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
			</p>

		return log

	buildHeroPowerLog: (action) ->
		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> uses </span>
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
			</p>

		return log

	buildPlayedSecretFromHandLog: (action) ->
		# console.log 'logging secret played', action, @replay.mainPlayerId, @replay
		if action.owner.id == parseInt(@replay.mainPlayerId)
			card = action.data['cardID']
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			link1 = <span>(</span>
			link2 = <span>)</span>
			# console.log '\tand building card link', card
		else

		log = <p key={++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays a </span> 
				<span className="secret-revealed">Secret </span>
				{link1}
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
				{link2}
			</p>

		return log

	buildTriggerSecretPlayLog: (action) ->
		if action.mainAction
			indent = <span className="indented-log">...which puts a <span className="secret-revealed">Secret</span>in play</span>

		secrets = []
		for secret in action.secrets
			card = secret['cardID']
			# Secret is public
			if action.owner == @replay.player
				cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
				secretLog = <span className="list">
						{indent}
						<span>: </span>
						<SpanDisplayLog newLog={cardLink} />
					</span>
				secrets.push secretLog
			else
				secrets.push <span className="list">
						{indent}
						<SpanDisplayLog newLog={''} />
					</span>


		log = <p key={++@logIndex}>
				{secrets}
			</p>

		return log

	buildPowerDamageLog: (action) ->
		# console.log 'building power-damage log', action
		if !action.sameOwnerAsParent
			card = if action.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>
		else 
			cardLog = <span>which </span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			cls = "indented-log"
			indentLog = <span>...</span>

		targets = @buildList action.target

		log = <p key={++@logIndex} className={cls}>
			    {indentLog}
			    {cardLog}
			    <span> deals {action.amount} damage to </span>
			    {targets}
			</p>

		return log

	buildPowerTargetLog: (action) ->
		# console.log 'buildPowerTargetLog', action
		if !action.sameOwnerAsParent
			card = if action.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>
		else 
			cardLog = <span>which </span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			cls = "indented-log"
			indentLog = <span>...</span>

		targets = @buildList action.target


		# target = @replay.entities[action.target]['cardID']
		# targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))

		log = <p key={++@logIndex} className={cls}>
			    {indentLog}
			    {cardLog}
			    <span> targets </span>
			    {targets}
			</p>

		return log

	buildPowerHealingLog: (action) ->
		# console.log 'building power-healing log', action
		if !action.sameOwnerAsParent
			card = if action.data then action.data['cardID'] else ''
			cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			cls = "indented-log"
			cardLog = <span>...which </span>

		targets = @buildList action.target

		log = <p key={++@logIndex} className={cls}>
			    {cardLog}
			    <span> heals </span> 
			    {targets}
			    <span> for {action.amount} life </span>
			</p>

		return log

	buildList: (actionIds) ->
		index = 1
		targets = []
		for targetId in actionIds
			target = @replay.entities[targetId]['cardID']
			targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))
			targets.push <SpanDisplayLog newLog={targetLink} />
			if actionIds.length > 1 
				if index == actionIds.length - 1
					targets.push <span key={++@logIndex}> and </span>
				else if index < actionIds.length - 1
					targets.push <span key={++@logIndex}>, </span>
			index++
		return targets

	buildPlayedCardWithTargetLog: (action) ->
		# console.log 'buildPlayedCardWithTargetLog', action
		target = @replay.entities[action.target]['cardID']
		targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))

		log = <p key={++@logIndex}>
			    <span className="indented-log">...which </span>
			    <span> targets </span>
			    <SpanDisplayLog newLog={targetLink} />
			</p>

		return log

	buildTriggerFullEntityLog: (action) ->
		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		creations = []
		for entity in action.newEntities
			target = entity['cardID']
			if target
				targetLink = @replay.buildCardLink(@replay.cardUtils.getCard(target))
				creationLog = <span key={++@logIndex} className="list"> 
					<SpanDisplayLog newLog={cardLink} />
					<span> creates </span>
					<SpanDisplayLog newLog={targetLink} />
				</span>
				creations.push creationLog

		log = <p key={++@logIndex}>
			    {creations}
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
		# card = @replay.entities[action.data]['cardID']
		# cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		targets = @buildList action.deads
		if targets.length > 1
			dies = <span> die </span>
		else
			dies = <span> dies </span>

		log = <p key={++@logIndex}>
			    {targets}
			    {dies}
			</p>

	buildDiscoverLog: (action) ->
		# console.log 'building discover log', action
		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		if !action.owner or action.owner.id == parseInt(@replay.mainPlayerId)
			# console.log 'discover for main player, showing everything'
			choicesCards = []
			for choice in action.choices
				choiceCard = choice['cardID']
				if choiceCard
					choiceCardLink = @replay.buildCardLink(@replay.cardUtils.getCard(choiceCard))
					choicesCards.push <SpanDisplayLog className="discovered-card indented-log" newLog={choiceCardLink} />

		log = <p key={++@logIndex}>
			    <SpanDisplayLog newLog={cardLink} />
			    <span> discovers </span>
			    {choicesCards}
			</p>

		return log

	buildSummonMinionLog: (action) ->
		# console.log 'buildSummonMinionLog', action
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

	buildNewHeroPowerLog: (action) ->
		card = action.data['cardID']
		cardLink = @replay.buildCardLink(@replay.cardUtils.getCard(card))

		log = <p key={++@logIndex}>
			    <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
			    <span className="new-hero-power"> receives a new Hero Power!! </span>
			    <SpanDisplayLog newLog={cardLink} />
			</p>

		return log

	buildFatigueDamageLog: (action) ->
		# console.log 'logging fatigue damage', action
		# The effect occured as a response to another action, so we need to make that clear
		if action.owner != @replay.getActivePlayer()
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
		else
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		fatigue = <span>  </span>

		log = <p key={++@logIndex}>
					{drawer}
					<span> takes {action.damage} fatigue damage</span>
				</p>

		return log

	# ===================
	# Turn specific log
	# ===================
	buildTurnLog: (turn) ->
		# console.log 'building turn log', turn
		if turn
			if turn.turn is 'Mulligan'
				log = @buildMulliganLog turn
				return log
			else 
				log = <p className="turn" key={++@logIndex}>
						<TurnDisplayLog turn={turn} active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} onClick={@props.onTurnClick.bind(this, turn.turn)} />
					</p>

				@replay.notifyNewLog log
				return [log]

	buildMulliganLog: (turn) ->
		log = <p className="turn turn-click" key={++@logIndex} onClick={@props.onTurnClick.bind(this, 0)}>Mulligan</p>

		@replay.notifyNewLog log

		logs = [log]
		# Additional data on cards mulliganed
		if turn.playerMulligan?.length > 0
			for mulliganed in turn.playerMulligan
				cardId = @replay.entities[mulliganed].cardID
				# console.log 'cardId', cardId
				card = @replay.cardUtils.getCard(cardId)
				# console.log 'card', card
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

	buildEndGameLog: (action) ->
		console.log 'logging end game', action
		log = <p className="turn end-game" key={++@logIndex}>End game</p>
		return log

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
		$("#turnLog").scrollTo("max")
		
	render: ->
		if @props.active
			return <span key={++@logIndex}>
				<span onClick={@props.onClick} className="turn-click" key={++@logIndex}>{'Turn ' + Math.ceil(@props.turn.turn / 2) + ' - '}</span>
				<PlayerNameDisplayLog active={true} name={@props.name} />
			</span>
		else
			return <span key={++@logIndex}>
				<span onClick={@props.onClick} className="turn-click" key={++@logIndex}>{'Turn ' + Math.ceil(@props.turn.turn / 2) + 'o - '}</span>
				<PlayerNameDisplayLog active={false} name={@props.name} />
			</span>

PlayerNameDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")
	
	render: ->
		if @props.active 
			return <span className="main-player" key={++@logIndex}>{@props.name}</span>
		else
			return <span className="opponent" key={++@logIndex}>{@props.name}</span>


ActionDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")

	render: ->
		cls = @props.className
		cls += " action"
		return <p className={cls} key={++@logIndex} dangerouslySetInnerHTML={{__html: @props.newLog}}></p>

SpanDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")

	render: ->
		cls = @props.className
		cls += " action"
		return <span className={cls} key={++@logIndex} dangerouslySetInnerHTML={{__html: @props.newLog}}></span>


module.exports = TurnLog
