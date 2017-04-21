React = require 'react'

class Timeline extends React.Component

	render: ->
		replay = @props.replay
		@replay = replay

		return null unless replay.getTotalLength()

		# console.log 'rendering timeline', replay.getTotalLength(), replay.getElapsed()

		length = replay.getTotalLength()
		totalSeconds = "" + Math.floor(length % 60)
		if totalSeconds.length < 2
			totalSeconds = "0" + totalSeconds
		totalMinutes = Math.floor(length / 60)
		if totalMinutes.length < 2
			totalMinutes = "0" + totalMinutes

		position = replay.getElapsed()
		elapsedSeconds = "" + Math.floor(position % 60)
		if elapsedSeconds.length < 2
			elapsedSeconds = "0" + elapsedSeconds
		elapsedMinutes = Math.floor(position / 60)
		if elapsedMinutes.length < 2
			elapsedMinutes = "0" + elapsedMinutes

		handleStyle =
			width: ((position / length) * 100) + '%'

		remaining = Math.floor(length - position)
		remainingSeconds = ""+(remaining % 60)
		if remainingSeconds.length < 2
			remainingSeconds = "0" + remainingSeconds
		remainingMinutes = Math.floor(remaining / 60)

		<div className="timeline">
			<div className="timeline-container">
				<div className="time-display" onClick={@moveToStart} title="Go back to the beginning">{elapsedMinutes}:{elapsedSeconds}</div>
				<div className="scrub-bar" onClick={this.handleClick} ref="scrub-bar">
					<div className="slider">
						<div className="current-time" style={handleStyle}></div>
					</div>
				</div>
				<div className="time-display" onClick={@moveToEnd} title="Go to the end">{totalMinutes}:{totalSeconds}</div>
			</div>
		</div>

	handleClick: (e) =>
		left = 0
		element = @refs['scrub-bar']
		target = element
		while (element != null) 
			left += (element.offsetLeft || 0)
			element = element.offsetParent

		progression = (e.clientX - left) / target.offsetWidth
		console.log 'moving to progression', progression, element, left, e.clientX, target, target.offsetWidth
		# This avoids small deviations and keeps the impression that we can click on the same point and not move the timeline
		progression = progression.toFixed(2)
		console.log 'rounded', progression
		@replay.moveTime(progression)

	moveToStart: (e) ->
		@replay.moveTime(0)

	moveToEnd: (e) ->
		@replay.moveTime(100)

module.exports = Timeline