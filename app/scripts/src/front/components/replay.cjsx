console.log('in replay')
React = require 'react'
{ButtonGroup, Button} = require 'react-photonkit'
ReplayPlayer = require '../../replay/replay-player'
HSReplayParser = require '../../replay/parsers/hs-replay'
PlayerName = require './ui/replay/player-name'
Hand = require './ui/replay/hand'
Deck = require './ui/replay/deck'
Mulligan = require './ui/replay/mulligan'
Board = require './ui/replay/board'
Mana = require './ui/replay/mana'
Health = require './ui/replay/health'
#Scrubber = require './ui/replay/scrubber'
Timeline = require './ui/replay/timeline'
GameLog = require './ui/replay/gamelog'
Play = require './ui/replay/play'
Target = require './ui/replay/target'

{subscribe} = require '../../subscription'
_ = require 'lodash'

class Replay extends React.Component
	constructor: (props) ->
		super(props)

		@state = replay: new ReplayPlayer(new HSReplayParser(props.route.replay))

		subscribe @state.replay, 'players-ready', =>
			#console.log 'in players-ready' 
			@callback

		subscribe @state.replay, 'moved-timestamp', =>
			#console.log 'in moved-timestamp'
			setTimeout @callback, 500

		#console.log('sub', @sub)
		@state.replay.init()

	componentWillUnmount: ->
		#@sub.off()

	callback: =>
		#console.log 'in callback'
		@forceUpdate()

	render: ->
		replay = @state.replay
		console.log 'rerendering replay'

		if replay.players.length == 2
			#console.log 'All players are here'

			top = <div className="top">
				<PlayerName entity={replay.opponent} />
				<Deck entity={replay.opponent} />
				<Board entity={replay.opponent} ref="topBoard"/>
				<Mulligan entity={replay.opponent} isHidden={true} />
				<Mana entity={replay.opponent} />
				<Health entity={replay.opponent} />
				<Play entity={replay.opponent} />
				<Hand entity={replay.opponent} isHidden={true} />
			</div>

			bottom = <div className="bottom">
				<PlayerName entity={replay.player} />
				<Deck entity={replay.player} />
				<Board entity={replay.player} ref="bottomBoard"/>
				<Mulligan entity={replay.player} isHidden={false} />
				<Mana entity={replay.player} />
				<Health entity={replay.player} />
				<Play entity={replay.player} />
				<Hand entity={replay.player} isHidden={false} />
			</div>

		else 
			console.warn 'Missing players', replay.players

		#console.log 'retrieving source and targets from', replay.targetSource, replay.targetDestination
		if this.refs['topBoard'] && this.refs['bottomBoard'] 
			#console.log 'topBoard cards', this.refs['topBoard'].getCardsMap
			source = @findCard this.refs['topBoard'].getCardsMap(), this.refs['bottomBoard'].getCardsMap(), replay.targetSource
			target = @findCard this.refs['topBoard'].getCardsMap(), this.refs['bottomBoard'].getCardsMap(), replay.targetDestination


		# {playButton}
		return <div className="replay">
					<form className="replay__controls padded">
						<ButtonGroup>
							<Button glyph="fast-backward" onClick={@goPreviousTurn}/>
							<Button glyph="to-start" onClick={@goPreviousAction}/>
							<Button glyph="to-end" onClick={@goNextAction}/>
							<Button glyph="fast-forward" onClick={@goNextTurn}/>
						</ButtonGroup>

						<Timeline replay={replay} />
					</form>
					<div className="replay__game">
						{top}
						{bottom}
						<Target source={source} target={target} />
					</div>
					
					<GameLog replay={replay} />
				</div>

	goNextAction: (e) =>
		e.preventDefault()
		@state.replay.goNextAction()
		@forceUpdate()

	goPreviousAction: (e) =>
		e.preventDefault()
		@state.replay.goPreviousAction()
		@forceUpdate()

	goNextTurn: (e) =>
		e.preventDefault()
		@state.replay.goNextTurn()
		@forceUpdate()

	goPreviousTurn: (e) =>
		e.preventDefault()
		@state.replay.goPreviousTurn()
		@forceUpdate()

	onClickPlay: (e) =>
		e.preventDefault()
		@state.replay.play()
		@forceUpdate()

	findCard: (topBoardCards, bottomBoardCards, cardID) ->
		#console.log 'finding card', topBoardCards, bottomBoardCards, cardID
		if !topBoardCards || !bottomBoardCards || !cardID
			return undefined

		#console.log 'topBoard cardsMap', topBoardCards, cardID
		card = topBoardCards[cardID]
		if !card
			card = bottomBoardCards[cardID]
		#console.log '\tFound card', card
		return card

module.exports = Replay
