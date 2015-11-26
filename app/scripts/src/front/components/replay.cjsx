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
Play = require './ui/replay/play'

{subscribe} = require '../../subscription'

class Replay extends React.Component
	constructor: (props) ->
		super(props)

		console.log 'initializing replay'
		@state = replay: new ReplayPlayer(new HSReplayParser(props.route.replay))
		console.log('state', @state)

		@sub = subscribe @state.replay, 'players-ready', => @callback

		@sub = subscribe @state.replay, 'moved-timestamp', =>
			console.log 'receiving moved-timestamp'
			setTimeout @callback, 1000

		console.log('sub', @sub)
		@state.replay.init()

	componentWillUnmount: ->
		console.log 'Replay will unmount'
		@sub.off()

	callback: =>
		console.log 'forcing update'
		@forceUpdate()

	render: ->
		replay = @state.replay
		console.log('rendering in replay', replay)

		if replay.players.length == 2
			console.log 'All players are here', replay.opponent, replay.player

			top = <div className="top">
				<PlayerName entity={replay.opponent} />
				<Deck entity={replay.opponent} />
				<Board entity={replay.opponent} />
				<Mulligan entity={replay.opponent} />
				<Mana entity={replay.opponent} />
				<Health entity={replay.opponent} />
				<Play entity={replay.opponent} />
				<Hand entity={replay.opponent} />
			</div>

			bottom = <div className="bottom">
				<PlayerName entity={replay.player} />
				<Deck entity={replay.player} />
				<Board entity={replay.player} />
				<Mulligan entity={replay.player} />
				<Mana entity={replay.player} />
				<Health entity={replay.player} />
				<Play entity={replay.player} />
				<Hand entity={replay.player} />
			</div>

		console.log 'top and bottom are', top, bottom
		return <div className="replay" key={replay.resetCounter}>
					<form className="replay__controls padded">
						<ButtonGroup>
							<Button glyph="pause" onClick={@onClickPause}/>
							<Button glyph="play" onClick={@onClickPlay} />
						</ButtonGroup>

						<Timeline replay={replay} />

						<div className="playback-speed">
							<div className="dropup"> 
								<button className="btn btn-default dropdown-toggle ng-binding" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true"> {@state.replay.getSpeed()}x <span className="caret"></span> </button> 
								<ul className="dropdown-menu" aria-labelledby="dropdownMenu1">
									<li><a onClick={@onClickChangeSpeed.bind(this, 1)}>1x</a></li> 
									<li><a onClick={@onClickChangeSpeed.bind(this, 2)}>2x</a></li> 
									<li><a onClick={@onClickChangeSpeed.bind(this, 4)}>4x</a></li> 
									<li><a onClick={@onClickChangeSpeed.bind(this, 8)}>8x</a></li> 
								</ul> 
							</div>
						</div>
					</form>
					<div className="replay__game">
						{top}
						{bottom}
					</div>
				</div>

	onClickPause: (e) =>
		e.preventDefault()
		@state.replay.pause()

	onClickPlay: (e) =>
		e.preventDefault()
		@state.replay.run()

	onClickChangeSpeed: (speed) ->
		console.log 'changing speed', speed
		@state.replay.changeSpeed speed
		@forceUpdate()


module.exports = Replay
