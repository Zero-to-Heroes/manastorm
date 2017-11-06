React = require 'react'

class CardText extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		controller = @props.replay.getController(entity.tags.CONTROLLER)
		@inTooltip = @props.inTooltip

		originalCard = cardUtils?.getCard(entity.cardID)

		console.log 'Trying to render text for', originalCard.name, entity.cardID, controller, entity

		damageBonus = 0
		doubleDamage = 0
		if controller
			damageBonus = controller.tags.CURRENT_SPELLPOWER || 0
			if entity.tags.RECEIVES_DOUBLE_SPELLDAMAGE_BONUS > 0
				damageBonus *= 2

		#console.log 'damageBonus', damageBonus
		description = originalCard.text?.replace('\n', '<br/>')
		description = description?.replace(/^\[x\]/, "");
		description = description?.replace(/\$(\d+)/g, @modifier(damageBonus, doubleDamage));
		console.log 'setting description', description

		@description = description

		# We need to keep the structure textFit will use so that changes to the description are properly propagated
		return <div className="card-text textFitAlignVertFlex" ref={ (div) => @cardText = div; } >
					<span className="textFitted textFitAlignVert">
						<p dangerouslySetInnerHTML={{ __html: description }}></p>
					</span>
				</div>

	updateText: ->
		#console.log 'updating text'
		setTimeout () =>
			rootFontSize = document.getElementById('replayMainArea').style.fontSize.split('px')[0]
			if rootFontSize <= 0
				@updateText()
			else
				maxFontSize = if @inTooltip then rootFontSize * 0.85 else rootFontSize * 0.5
				console.log 'max font sizes', @cardText?.toString(), maxFontSize
				textFit @cardText, {alignHoriz: true, alignVert: true, alignVertWithFlexbox: true, multiLine: true, minFontSize: 1, maxFontSize: maxFontSize}
				#console.log 'set font size', @cardText.offsetWidth, @cardText.offsetHeight, @cardText.style
		, 0

	componentDidMount: ->
		window.addEventListener 'resize', @updateText
		@updateText()

	modifier: (bonus, double) => 
		return (match, part1) =>
			#console.log 'applying modifier for', bonus, double, match, part1
			value = +part1
			if +bonus != 0 or +double != 0
				value += bonus
				value *= Math.pow(2, double)
				#console.log 'updated value', value
				return "*" + value + "*"
			return "" + value

module.exports = CardText
