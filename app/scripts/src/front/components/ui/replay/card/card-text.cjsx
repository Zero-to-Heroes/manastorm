React = require 'react'
{ Textfit } = require('react-textfit');

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
			textFit @cardText, {alignHoriz: true, alignVert: true, alignVertWithFlexbox: true, multiLine: true}
		, 20

module.exports = CardText
