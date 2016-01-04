console.log('in replay')
React = require 'react'
{ButtonGroup, Button} = require 'react-photonkit'
ReplayPlayer = require '../../replay/replay-player'
HSReplayParser = require '../../replay/parsers/hs-replay'
PlayerName = require './ui/replay/player-name'
Hand = require './ui/replay/hand'
Hero = require './ui/replay/hero'
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
		#console.log 'rerendering replay'

		if replay.players.length == 2
			#console.log 'All players are here'

			top = <div className="top">
				<PlayerName entity={replay.opponent} />
				<Deck entity={replay.opponent} />
				<Board entity={replay.opponent} ref="topBoard"/>
				<Mulligan entity={replay.opponent} isHidden={true} />
				<Mana entity={replay.opponent} />
				<Play entity={replay.opponent} />
				<Hand entity={replay.opponent} isHidden={true} />
				<Hero entity={replay.opponent} ref="topHero"/>
			</div>

			bottom = <div className="bottom">
				<PlayerName entity={replay.player} />
				<Deck entity={replay.player} />
				<Board entity={replay.player} ref="bottomBoard"/>
				<Mulligan entity={replay.player} isHidden={false} />
				<Mana entity={replay.player} />
				<Play entity={replay.player} />
				<Hero entity={replay.player} ref="bottomHero" />
				<Hand entity={replay.player} isHidden={false} />
			</div>

		else 
			console.warn 'Missing players', replay.players

		#console.log 'retrieving source and targets from', replay.targetSource, replay.targetDestination
		if this.refs['topBoard'] and this.refs['bottomBoard'] and this.refs['topHero'] and this.refs['bottomHero'] 
			#console.log 'topBoard cards', this.refs['topBoard'].getCardsMap
			allCards = @merge this.refs['topBoard'].getCardsMap(), this.refs['bottomBoard'].getCardsMap(), this.refs['topHero'].getCardsMap(), this.refs['bottomHero'].getCardsMap()
			#console.log 'merged cards', allCards
			source = @findCard allCards, replay.targetSource
			target = @findCard allCards, replay.targetDestination


		# {playButton}
		return <div className="replay">
					<div className="replay__game">
						{top}
						{bottom}
						<Target source={source} target={target} />
					</div>
					<form className="replay__controls padded">
						<ButtonGroup>
							<Button glyph="fast-backward" onClick={@goPreviousTurn}/>
							<Button glyph="to-start" onClick={@goPreviousAction}/>
							<Button glyph="to-end" onClick={@goNextAction}/>
							<Button glyph="fast-forward" onClick={@goNextTurn}/>
						</ButtonGroup>
						<Timeline replay={replay} />
					</form>
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

	findCard: (allCards, cardID) ->
		#console.log 'finding card', topBoardCards, bottomBoardCards, cardID
		if !allCards || !cardID
			return undefined

		#console.log 'topBoard cardsMap', topBoardCards, cardID
		card = allCards[cardID]
		#console.log '\tFound card', card
		return card

	# https://gist.github.com/sheldonh/6089299
	merge: (xs...) ->
	  	if xs?.length > 0
	    	tap {}, (m) -> m[k] = v for k,v of x for x in xs
		tap = (o, fn) -> fn(o); o

module.exports = Replay
