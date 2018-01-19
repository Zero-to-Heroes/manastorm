React = require 'react'

class CardName extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)
		@name = originalCard.name

		if originalCard.type is 'Minion'
			pathId = 'minionPath'
			path = <path id={pathId} d="M 0,130 C 30,140 100,140 180,125 M 180,125 C 250,110 750,-15 1000,100" ref={ (path) => @minionPathRef = path; } />
		else if originalCard.type is 'Spell'
			pathId = 'spellPath'
			path = <path id={pathId} d="M 0,140 Q 500,-23 1000,154" />
		else if originalCard.type is 'Weapon'
			pathId = 'weaponPath'
			path = <path id={pathId} d="M 0,50 H 1000" />
		else if originalCard.type is 'Hero_power'
			pathId = 'heroPowerPath'
			path = <path id={pathId} d="M 0,50 H 1000" />
		else if originalCard.type is 'Hero'
			pathId = 'heroPath'
			path = <path id={pathId} d="M 0,180 Q 500,-63 1000,180" />

		# @updateText()

		useTag = '<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#weaponPath" fill="none" stroke="red" stroke-width="20px" />'
		svgDebugStyle = {position: "absolute", left: 0, bottom: 0}
		svgDebug = null #<svg x="0" y ="0" viewBox="0 0 1000 200" style={svgDebugStyle} dangerouslySetInnerHTML={{__html: useTag }} />;

		# http://www.east5th.co/blog/2014/10/08/quest-for-scalable-svg-text/
		return <div className="name-text">
					<svg x="0" y ="0" viewBox="0 0 1000 200" ref={ (svg) => @svgRef = svg; } >
						<defs>
							{path}
						</defs>
						<text textAnchor="middle" ref={ (text) => @text = text; } >
							<textPath startOffset="50%" xlinkHref={'#' + pathId}>{@name}</textPath>
						</text>
					</svg>
					{svgDebug}
				</div>


	updateText: ->
		setTimeout () =>
			if !@svgRef
				return

			bb = @svgRef.getBBox()

			rootFontSize = document.getElementById('replayMainArea').style.fontSize.split('px')[0]
			if rootFontSize <= 0
				@updateText()
			else
				fontSize = rootFontSize * 7
				# Fumbling around a bit to make big names fit in the text box
				if @name.length > 16
					fontSize = rootFontSize * 6

				@text.setAttribute("font-size", fontSize)
		, 50

	updatePath: (initialValue, previousMin, previousLength, newMin, newLength) =>
		return newMin + (initialValue - previousMin) * (newLength / previousLength)

	componentDidMount: ->
		window.addEventListener 'resize', @updateText
		@updateText()

module.exports = CardName
