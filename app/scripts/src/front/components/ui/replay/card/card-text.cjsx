React = require 'react'

class CardText extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		originalCard = cardUtils?.getCard(entity.cardID)

		@updateText()

		return <div className="card-text" ref={ (div) => @cardText = div; } >
					<p dangerouslySetInnerHTML={{ __html: originalCard.text?.replace('\n', '<br/>') }}></p>
				</div>

	updateText: ->
		setTimeout () =>
			rootFontSize = document.getElementById('replayMainArea').style.fontSize.split('px')[0]
			if rootFontSize <= 0
				@updateText()
			else
				console.log 'min max font sizes', document.getElementById('replayMainArea').style.fontSize, rootFontSize * 0.8
				textFit @cardText, {alignHoriz: true, alignVert: true, alignVertWithFlexbox: true, multiLine: true, minFontSize: 1, maxFontSize: rootFontSize * 0.9}
				console.log 'set font size', @cardText.offsetWidth, @cardText.offsetHeight, @cardText.style
		, 50

module.exports = CardText
