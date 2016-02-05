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
Turn = require './ui/replay/turn'
TurnLog = require './ui/replay/turnLog'

ReactTooltip = require("react-tooltip")
{subscribe} = require '../../subscription'
_ = require 'lodash'

class Replay extends React.Component
	constructor: (props) ->
		super(props)

		@state = replay: new ReplayPlayer(new HSReplayParser(props.route.replay))

		@showAllCards = false
		@mainPlayerSwitched = false

		subscribe @state.replay, 'players-ready', =>
			#console.log 'in players-ready' 
			@callback

		subscribe @state.replay, 'moved-timestamp', =>
			#console.log 'in moved-timestamp'
			setTimeout @callback, 500

		#console.log('sub', @sub)
		@state.replay.init()
		#console.log 'first init done'
		# @state.replay.buildGameLog()
		#console.log 'log built'
		#@state.replay.init()
		#console.log 'second init done'

		@displayConf = {
			showLog: false
		}

	callback: =>
		#console.log 'in callback'
		@forceUpdate()

	render: ->
		replay = @state.replay

		#console.log 'rerendering replay'

		if replay.players.length == 2
			#console.log 'All players are here'

			top = <div className="top">
				<PlayerName entity={replay.opponent} isActive={replay.opponent.id == replay.getActivePlayer().id}/>
				<Deck entity={replay.opponent} />
				<Board entity={replay.opponent} ref="topBoard" tooltips={true}/>
				<Mulligan entity={replay.opponent} mulligan={replay.turns[1].opponentMulligan} isHidden={!@showAllCards} />
				<Mana entity={replay.opponent} />
				<Play entity={replay.opponent} />
				<Hand entity={replay.opponent} isHidden={!@showAllCards} />
				<Hero entity={replay.opponent} ref="topHero"/>
			</div>

			bottom = <div className="bottom">
				<PlayerName entity={replay.player} isActive={replay.player.id == replay.getActivePlayer().id}/>
				<Deck entity={replay.player} />
				<Board entity={replay.player} ref="bottomBoard" tooltips={true}/>
				<Mulligan entity={replay.player} mulligan={replay.turns[1].playerMulligan} isHidden={false} />
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
		playButton = <Button glyph="play" onClick={@onClickPlay} />

		if @state.replay.speed > 0
			playButton = <Button glyph="pause" onClick={@onClickPause}/>

		return <div className="replay">
					<ReactTooltip />
					<div className="additional-controls">
						<label>
							<input type="checkbox" checked={@showAllCards} onChange={@onShowCardsChange} />Try to show hidden cards
						</label>
						<label>
							<input type="checkbox" checked={@mainPlayerSwitched} onChange={@onMainPlayerSwitchedChange} />Switch main player
						</label>
					</div>
					<div className="replay__game">
						{top}
						{bottom}
						<Target source={source} target={target} type={replay.targetType}/>
						<Turn replay={replay} onClick={@onTurnClick} active={@displayConf.showLog }/>
					</div>
					<TurnLog show={@displayConf.showLog} replay={replay}/>
					<form className="replay__controls padded">
						<ButtonGroup>
							<Button glyph="fast-backward" onClick={@goPreviousTurn}/>
							<Button glyph="to-start" onClick={@goPreviousAction}/>
							{playButton}
							<Button glyph="to-end" onClick={@goNextAction}/>
							<Button glyph="fast-forward" onClick={@goNextTurn}/>
						</ButtonGroup>
						<Timeline replay={replay} />
						<div className="playback-speed">
							<div className="dropup"> 
								<button className="btn btn-default dropdown-toggle ng-binding" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true"> {@state.replay.speed}x <span className="caret"></span> </button> 
								<ul className="dropdown-menu" aria-labelledby="dropdownMenu1">
									<li><a onClick={@onClickChangeSpeed.bind(this, 1)}>1x</a></li> 
									<li><a onClick={@onClickChangeSpeed.bind(this, 2)}>2x</a></li> 
									<li><a onClick={@onClickChangeSpeed.bind(this, 4)}>4x</a></li> 
									<li><a onClick={@onClickChangeSpeed.bind(this, 8)}>8x</a></li> 
								</ul> 
							</div>
						</div>
					</form>
					<GameLog replay={replay} onLogClick={@onTurnClick} />
				</div>

	goNextAction: (e) =>
		e.preventDefault()
		@state.replay.pause()
		@state.replay.goNextAction()
		@forceUpdate()

	goPreviousAction: (e) =>
		e.preventDefault()
		@state.replay.pause()
		@state.replay.goPreviousAction()
		@forceUpdate()

	goNextTurn: (e) =>
		e.preventDefault()
		@state.replay.pause()
		@state.replay.goNextTurn()
		@forceUpdate()

	goPreviousTurn: (e) =>
		e.preventDefault()
		@state.replay.pause()
		@state.replay.goPreviousTurn()
		@forceUpdate()

	onClickPlay: (e) =>
		e.preventDefault()
		@state.replay.autoPlay()
		@forceUpdate()

	onClickPause: (e) =>
		e.preventDefault()
		@state.replay.pause()
		@forceUpdate()

	onClickChangeSpeed: (speed) ->
		@state.replay.changeSpeed speed
		@forceUpdate()

	onShowCardsChange: =>
		@showAllCards = !@showAllCards
		@forceUpdate()

	onMainPlayerSwitchedChange: =>
		@mainPlayerSwitched = !@mainPlayerSwitched
		@state.replay.switchMainPlayer()
		@forceUpdate()

	onTurnClick: (e) =>
		console.log 'clicked on turn'
		e.preventDefault()
		@displayConf.showLog = !@displayConf.showLog
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
