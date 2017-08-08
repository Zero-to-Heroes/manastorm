React = require 'react'
{ Textfit } = require('react-textfit');

class CardName extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		if originalCard.type is 'Minion'
			pathId = 'minionPath'
			path = <path id={pathId} d="M 0,20 C 50,30 150,-10 200,20" />
		else if originalCard.type is 'Spell'
			pathId = 'spellPath'
			path = <path id={pathId} d="M 0,30 Q 100,-10 200,30" />
		# TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
		else if originalCard.type is 'Weapon'
			pathId = 'weaponPath'
			path = <path id={pathId} d="M 0,20 C 50,30 150,-10 200,20" />

		@updateText()

		# http://www.east5th.co/blog/2014/10/08/quest-for-scalable-svg-text/
		return <div className="name-text">
					<svg x="0" y ="0" width="100%" height="100%" viewBox="0 0 200 30" ref={ (svg) => @svgRef = svg; } >
						<defs>
							{path}
						</defs>
						<text textAnchor="middle" >
							<textPath startOffset="50%" xlinkHref={'#' + pathId}>{originalCard.name}</textPath>
						</text>
					</svg>
				</div>


	updateText: ->
		setTimeout () =>
			bb = @svgRef.getBBox()
			@svgRef.setAttribute("viewBox", [bb.x, bb.y, bb.width, bb.height].join(' '))
		, 0

module.exports = CardName
