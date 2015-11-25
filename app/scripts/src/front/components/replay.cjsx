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

		# replayPath = "#{__dirname + '/../../../replay/sample.xml'}"
		# console.log('replayPath', replayPath)

		console.log 'initializing replay'
		@state = replay: new ReplayPlayer(new HSReplayParser(props.route.replay))
		console.log('state', @state)

		@sub = subscribe @state.replay, 'players-ready', => @forceUpdate()
		console.log('sub', @sub)
		@state.replay.init()

	componentWillUnmount: ->
		@sub.off()

	render: ->
		replay = @state.replay
		console.log('rendering in replay', replay)

		if replay.players.length == 2
			console.log 'All players are here'

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
		return <div className="replay">
			<form className="replay__controls padded">
				<ButtonGroup>
					<Button glyph="pause" onClick={@onClickPause}/>
					<Button glyph="play" onClick={@onClickPlay} />
					<Button glyph="fast-forward" onClick={@onClickFastForward} />
				</ButtonGroup>

				<Timeline replay={replay} />
			</form>
			<div className="replay__game">
				{top}
				{bottom}
			</div>
		</div>

	onClickPause: (e) =>
		console.log 'pausing', @state
		e.preventDefault()
		@state.replay.pause()

	onClickPlay: (e) =>
		console.log 'clicked on play, running', @state
		e.preventDefault()
		@state.replay.run()

	onClickFastForward: ->

module.exports = Replay
