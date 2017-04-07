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
				# console.log 'adding log line', logLine, action, action, action?.data?.cardID

		@subs.add @replay, 'previous-action', (action) =>
			popped = @logs.pop()
			# console.log 'popping last element from game log', popped, action, action?.data?.cardID

		@subs.add @replay, 'new-turn', (turn) =>
			newLog = @buildTurnLog turn
			@logs.push newLog
			# console.log 'adding turn line', newLog, turn

		@subs.add @replay, 'reset',  =>
			@logs = []

		@replay.forceReemit()

	render: ->
		return null unless @props.show and !@props.hide

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

		else if action.actionType == 'quest-completed'
			log = @buildQuestCompletedLog action

		else if action.actionType == 'played-card-from-hand'
			log = @buildPlayedCardFromHandLog action

		else if action.actionType == 'hero-power'
			log = @buildHeroPowerLog action

		else if action.actionType == 'played-secret-from-hand'
			log = @buildPlayedSecretFromHandLog action

		else if action.actionType == 'played-quest-from-hand'
			log = @buildPlayedQuestFromHandLog action

		else if action.actionType == 'power-damage'
			log = @buildPowerDamageLog action

		else if action.actionType == 'power-healing'
			log = @buildPowerHealingLog action

		else if action.actionType == 'power-target'
			log = @buildPowerTargetLog action

		else if action.actionType == 'splash-reveal'
			log = @buildSplashRevealLog action

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
		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		newLog = '<span><span class="secret-revealed">\tSecret revealed! </span>' + cardLink + '</span>'
		log = <ActionDisplayLog newLog={newLog} />

		@replay.notifyNewLog log

		return [log]

	buildQuestCompletedLog: (action) ->
		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		newLog = '<span><span class="secret-revealed">\tQuest completed! </span>' + cardLink + '</span>'
		log = <ActionDisplayLog newLog={newLog} />

		@replay.notifyNewLog log

		return [log]

	buildCardDrawLog: (action) ->
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
		indent = <span key={'log' + ++@logIndex}></span>
		if action.mainAction
			indentText = '<span>...and </span>'
			indent = <SpanDisplayLog className="indented-log" newLog={indentText} />
			if action.owner != @replay.getActivePlayer()
				drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
		else
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		drawLog = <p key={'log' + ++@logIndex}>
					{indent}
					{drawer}
					<span key={'log' + ++@logIndex}> draws </span>
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
		indent = <span key={'log' + ++@logIndex}></span>
		if action.mainAction
			indentText = '<span>...and </span>'
			indent = <SpanDisplayLog className="indented-log" newLog={indentText} />
			if action.owner != @replay.getActivePlayer()
				drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
		else
			drawer = <PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />

		drawLog = <p key={'log' + ++@logIndex}>
					{indent}
					{drawer}
					<span key={'log' + ++@logIndex}> discards </span>
					{cardLink}
				</p>

		return drawLog

	buildOverdrawLog: (action) ->
		if action.owner == @replay.player
			cardLink = @buildList action.data
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

		drawLog = <p key={'log' + ++@logIndex}>
					{indent}
					{drawer}
					<span className="overdraw" key={'log' + ++@logIndex}> overdraws </span>
					{cardLink}
				</p>

		return drawLog

	buildPlayedCardFromHandLog: (action) ->
		# card = action.data['cardID']
		# console.log 'buildPlayedCardFromHandLog', action, card
		cardLink = @buildCardLink action.data

		log = <p key={'log' + ++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays </span>
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
			</p>

		return log

	buildHeroPowerLog: (action) ->
		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		log = <p key={'log' + ++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> uses </span>
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
			</p>

		return log

	buildPlayedSecretFromHandLog: (action) ->
		# console.log 'logging secret played', action, @replay.mainPlayerId, @replay
		if action.owner.id == parseInt(@replay.mainPlayerId)
			# card = action.data['cardID']
			cardLink = @buildCardLink action.data
			link1 = <span>(</span>
			link2 = <span>)</span>
			# console.log '\tand building card link', card
		else

		log = <p key={'log' + ++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays a </span> 
				<span className="secret-revealed">Secret </span>
				{link1}
				<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
				{link2}
			</p>

		return log

	buildPlayedQuestFromHandLog: (action) ->
		# console.log 'logging quest played', action, @replay.mainPlayerId, @replay
		if action.owner.id == parseInt(@replay.mainPlayerId)
			# card = action.data['cardID']
			cardLink = @buildCardLink action.data
			link1 = <span>(</span>
			link2 = <span>)</span>
			# console.log '\tand building card link', card
		else

		log = <p key={'log' + ++@logIndex}>
				<PlayerNameDisplayLog active={action.owner == @replay.player} name={action.owner.name} />
				<span> plays a </span> 
				<span className="secret-revealed">Quest </span>
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
			# card = secret['cardID']
			# Secret is public
			if action.owner == @replay.player
				cardLink = @buildCardLink secret
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


		log = <p key={'log' + ++@logIndex}>
				{secrets}
			</p>

		return log

	buildPowerDamageLog: (action) ->
		# console.log 'building power-damage log', action
		if !action.sameOwnerAsParent
			# card = if action.data then action.data['cardID'] else ''
			cardLink = @buildCardLink action.data
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>
		else 
			cardLog = <span>which </span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			cls = "indented-log"
			indentLog = <span>...</span>

		targets = []
		targetsByValue = {}
		for k, v of action.targets
			if !targetsByValue[v]
				targetsByValue[v] = []
			targetsByValue[v].push k

		for k, v of targetsByValue
			# console.log 'building damage link', k, v, action.targets
			cardLink = @buildList v
			targets.push <span><span> {k} damage to </span>{cardLink},</span>

		# targets = @buildList action.target

		log = <p key={'log' + ++@logIndex} className={cls}>
			    {indentLog}
			    {cardLog}
			    <span> deals </span>
			    {targets}
			</p>

		return log

	buildPowerTargetLog: (action) ->
		# console.log 'buildPowerTargetLog', action
		if !action.sameOwnerAsParent
			# card = if action.data then action.data['cardID'] else ''
			cardLink = @buildCardLink action.data
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>
		else 
			cardLog = <span>which </span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			cls = "indented-log"
			indentLog = <span>...</span>

		# console.log 'building targets log', action
		targets = @buildList action.target, action

		log = <p key={'log' + ++@logIndex} className={cls}>
			    {indentLog}
			    {cardLog}
			    <span> targets </span>
			    {targets}
			</p>

		return log

	buildPowerHealingLog: (action) ->
		# console.log 'building power-healing log', action
		if !action.sameOwnerAsParent
			# card = if action.data then action.data['cardID'] else ''
			cardLink = @buildCardLink action.data
			cardLog = <span dangerouslySetInnerHTML={{__html: cardLink}}></span>
		else 
			cardLog = <span>which </span>

		# The effect occured as a response to another action, so we need to make that clear
		if action.mainAction
			cls = "indented-log"
			indentLog = <span>...</span>

		targets = []
		targetsByValue = {}
		for k, v of action.targets
			if !targetsByValue[v]
				targetsByValue[v] = []
			targetsByValue[v].push k

		for k, v of targetsByValue
			# console.log 'building damage link', k, v, action.targets
			cardLink = @buildList v
			targets.push <span>{cardLink}<span> for {k} life </span>,</span>


		log = <p key={'log' + ++@logIndex} className={cls}>
			    {indentLog}
			    {cardLog}
			    <span> heals </span> 
			    {targets}
			</p>

		return log

	buildSplashRevealLog: (action) ->
		cardLink = @buildCardLink action.data
		cardLog =  <SpanDisplayLog newLog={cardLink} /> 

		log = <p key={'log' + ++@logIndex}>
			    {cardLog}
			    <span> reveals himself!</span>
			</p>

		return log



	buildList: (actionIds, action) ->
		index = 1
		targets = []

		# console.log 'building list', action, actionIds
		if action and action.revealTarget and !action.revealTarget(@replay)
			hiddenLink = '' + actionIds.length + ' cards'
			targets.push <SpanDisplayLog newLog={hiddenLink} /> 

		else
			for targetId in actionIds
				# target = @replay.entities[targetId]['cardID']
				targetLink = @buildCardLink @replay.entities[targetId]
				targets.push <SpanDisplayLog newLog={targetLink} />
				if actionIds.length > 1 
					if index == actionIds.length - 1
						targets.push <span key={'log' + ++@logIndex}> and </span>
					else if index < actionIds.length - 1
						targets.push <span key={'log' + ++@logIndex}>, </span>
				index++

		return targets

	buildPlayedCardWithTargetLog: (action) ->
		# console.log 'buildPlayedCardWithTargetLog', action
		target = @replay.entities[action.target]['cardID']
		targetLink = @buildCardLink @replay.entities[action.target]

		log = <p key={'log' + ++@logIndex}>
			    <span className="indented-log">...which </span>
			    <span> targets </span>
			    <SpanDisplayLog newLog={targetLink} />
			</p>

		return log

	buildTriggerFullEntityLog: (action) ->
		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		creations = []
		for entity in action.newEntities
			# target = entity['cardID']
			if entity['cardID']
				targetLink = @buildCardLink entity # @replay.buildCardLink(@replay.cardUtils.getCard(target))
				creationLog = <span key={'log' + ++@logIndex} className="list"> 
					<SpanDisplayLog newLog={cardLink} />
					<span> creates </span>
					<SpanDisplayLog newLog={targetLink} />
				</span>
				creations.push creationLog

		log = <p key={'log' + ++@logIndex}>
			    {creations}
			</p>

		return log

	buildAttackLog: (action) ->
		# card = if action.data then action.data['cardID'] else ''
		cardLink = @buildCardLink action.data

		# target = @replay.entities[action.target]['cardID']
		targetLink = @buildCardLink @replay.entities[action.target] # @replay.buildCardLink(@replay.cardUtils.getCard(target))

		log = <p key={'log' + ++@logIndex}>
			    <SpanDisplayLog newLog={cardLink} />
			    <span> attacks </span>
			    <span dangerouslySetInnerHTML={{__html: targetLink}}></span>
			</p>

		return log

	buildMinionDeathLog: (action) ->
		targets = @buildList action.deads
		if targets.length > 1
			dies = <span> die </span>
		else
			dies = <span> dies </span>

		log = <p key={'log' + ++@logIndex}>
			    {targets}
			    {dies}
			</p>

	buildDiscoverLog: (action) ->
		# console.log 'building discover log', action
		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		if !action.owner or action.owner.id == parseInt(@replay.mainPlayerId)
			# console.log 'discover for main player, showing everything'
			choicesCards = []
			for choice in action.choices
				choiceCard = choice['cardID']
				if choiceCard
					choiceCardLink = @buildCardLink choice # @replay.buildCardLink(@replay.cardUtils.getCard(choiceCard))
					choicesCards.push <SpanDisplayLog className="discovered-card indented-log" newLog={choiceCardLink} />

		log = <p key={'log' + ++@logIndex}>
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

		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		log = <p key={'log' + ++@logIndex}>
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

		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		log = <p key={'log' + ++@logIndex}>
			    {indent}
			    <span> equips </span>
			    <SpanDisplayLog newLog={cardLink} />
			</p>

		return log

	buildNewHeroPowerLog: (action) ->
		# card = action.data['cardID']
		cardLink = @buildCardLink action.data

		log = <p key={'log' + ++@logIndex}>
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

		log = <p key={'log' + ++@logIndex}>
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
				log = <p className="turn" key={'log' + ++@logIndex}>
						<TurnDisplayLog turn={turn} active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} onClick={@props.onTurnClick.bind(this, turn.turn)} />
					</p>

				@replay.notifyNewLog log
				return [log]

	buildMulliganLog: (turn) ->
		log = <p className="turn turn-click" key={'log' + ++@logIndex} onClick={@props.onTurnClick.bind(this, 0)}>Mulligan</p>

		@replay.notifyNewLog log

		logs = [log]
		# Additional data on cards mulliganed
		if turn.playerMulligan?.length > 0
			for mulliganed in turn.playerMulligan
				# cardId = @replay.entities[mulliganed].cardID
				# console.log 'cardId', cardId
				# card = @replay.cardUtils.getCard(cardId)
				# console.log 'card', card
				cardLink = @buildCardLink @replay.entities[mulliganed]
				cardLog = <p key={'log' + ++@logIndex}>
							<PlayerNameDisplayLog active={true} name={@replay.player.name} />
							<span> mulligans </span>
							<span dangerouslySetInnerHTML={{__html: cardLink}}></span>
						</p>
				logs.push cardLog

		if turn.opponentMulligan?.length > 0
			cardLog = <p key={'log' + ++@logIndex}>
				<PlayerNameDisplayLog active={false} name={@replay.opponent.name} /> mulligans {turn.opponentMulligan.length} cards
			</p>
			logs.push cardLog

		return logs

	buildEndGameLog: (action) ->
		# console.log 'logging end game', action
		log = <p className="turn end-game" key={'log' + ++@logIndex}>End game</p>
		return log

	# ===============
	# Utilities
	# ===============
	playerName: (turn) -> 
		return <PlayerNameDisplayLog active={turn.activePlayer == @replay.player} name={turn.activePlayer.name} />

	buildCardLink: (entity) ->
		# If the card is hidden and the "show hidden card" not activated, we don't show the card
		# For now, hidden only means "in hand"
		cardID = if entity then entity['cardID'] else ''
		return @replay.buildCardLink(@replay.cardUtils.getCard(cardID), null, '#externalPlayer')

# ===============
# And DRY objects
# ===============


TurnDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")
		
	render: ->
		if @props.active
			return <span key={'log' + ++@logIndex}>
				<span onClick={@props.onClick} className="turn-click" key={'log' + ++@logIndex}>{'Turn ' + Math.ceil(@props.turn.turn / 2) + ' - '}</span>
				<PlayerNameDisplayLog active={true} name={@props.name} />
			</span>
		else
			return <span key={'log' + ++@logIndex}>
				<span onClick={@props.onClick} className="turn-click" key={'log' + ++@logIndex}>{'Turn ' + Math.ceil(@props.turn.turn / 2) + 'o - '}</span>
				<PlayerNameDisplayLog active={false} name={@props.name} />
			</span>

PlayerNameDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")
	
	render: ->
		if @props.active 
			return <span className="main-player" key={'log' + ++@logIndex}>{@props.name}</span>
		else
			return <span className="opponent" key={'log' + ++@logIndex}>{@props.name}</span>


ActionDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")

	render: ->
		cls = @props.className
		cls += " action"
		return <p className={cls} key={'log' + ++@logIndex} dangerouslySetInnerHTML={{__html: @props.newLog}}></p>

SpanDisplayLog = React.createClass
	componentDidMount: ->
		$("#turnLog").scrollTo("max")

	render: ->
		cls = @props.className
		cls += " action"
		return <span className={cls} key={'log' + ++@logIndex} dangerouslySetInnerHTML={{__html: @props.newLog}}></span>


module.exports = TurnLog
