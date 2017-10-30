React = require 'react'

class CardName extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		if originalCard.type is 'Minion'
			pathId = 'minionPath'
			path = <path id={pathId} d="M 0,130 C 30,140 100,140 180,125 M 180,125 C 250,110 750,-15 1000,100" ref={ (path) => @minionPathRef = path; } />
		else if originalCard.type is 'Spell'
			pathId = 'spellPath'
			path = <path id={pathId} d="M 0,140 Q 500,-23 1000,154" />
		else if originalCard.type is 'Weapon'
			pathId = 'weaponPath'
			path = <path id={pathId} d="M 0,50 H 1000" />

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
							<textPath startOffset="50%" xlinkHref={'#' + pathId}>{originalCard.name}</textPath>
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
				@text.setAttribute("font-size", rootFontSize * 7)
		, 50

	updatePath: (initialValue, previousMin, previousLength, newMin, newLength) => 
		return newMin + (initialValue - previousMin) * (newLength / previousLength)

	componentDidMount: ->
		window.addEventListener 'resize', @updateText
		@updateText()

module.exports = CardName
