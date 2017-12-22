React = require 'react'
ReactDOM = require 'react-dom'
_ = require 'lodash'
textFit = require 'textFit-z2h'

class CardText extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity
		controller = @props.replay.getController(entity.tags?.CONTROLLER)
		#@inTooltip = @props.inTooltip

		originalCard = cardUtils?.getCard(entity.cardID)

		# console.log 'Trying to render text for', originalCard.name, entity.cardID, controller, entity, originalCard, originalCard.referencedTags

		damageBonus = 0
		doubleDamage = 0
		if controller
			if originalCard.type is 'Spell'
				damageBonus = controller.tags.CURRENT_SPELLPOWER || 0
				if entity.tags.RECEIVES_DOUBLE_SPELLDAMAGE_BONUS > 0
					damageBonus *= 2
				doubleDamage = controller.tags.SPELLPOWER_DOUBLE || 0
			else if originalCard.type is 'Hero_power'
				damageBonus = controller.tags.CURRENT_HEROPOWER_DAMAGE_BONUS || 0
				doubleDamage = controller.tags.HERO_POWER_DOUBLE || 0

		description = originalCard.text?.replace('\n', '<br/>')

		# Kazakus
		if entity.tags.TAG_SCRIPT_DATA_NUM_1 and entity.tags.TAG_SCRIPT_DATA_NUM_2
			data1 = entity.tags.TAG_SCRIPT_DATA_NUM_1
			data2 = entity.tags.TAG_SCRIPT_DATA_NUM_2
			arg1 = ''
			arg2 = ''
			# Get the ones created by the entity
			# console.log 'trying to get Kazakus text', entity
			effects = _.filter @props.replay.entities, (e) =>
				e.tags.CREATOR is entity.id and e.tags.ZONE is 6
			# console.log 'efffects', effects
			effects.forEach (effect) =>
				if effect.tags.TAG_SCRIPT_DATA_NUM_1 is data1
					arg1 = cardUtils.getCard(effect.cardID).text
				if effect.tags.TAG_SCRIPT_DATA_NUM_1 is data2
					arg2 = cardUtils.getCard(effect.cardID).text
			description = description.replace('{0}', arg1).replace('{1}', arg2)

		# We can't rely on the "Mechanics" tag, as Jade Chieftain doesn't have it. Aya BLackpaw doesn't have the JADE8GOLEM referencedTag, and Jade Golems have it but have no description
		# So we add extra checks and run this last to be sure it doesn't interfere wiht anything else
		if entity.tags.JADE_GOLEM or (originalCard.referencedTags and 'JADE_GOLEM' in originalCard.referencedTags) and description and description.indexOf('{0}') != -1 and description.indexOf('{1}') != -1

			console.log 'setting JADE_GOLEM'
			value = (controller.tags.JADE_GOLEM or 0) + 1
			arg1 = if value in [8, 11, 18] then 'n' else ''
			description = description.replace('{0}', value + '/' + value).replace('{1}', arg1)

		# Replace &nbsp;
		description = description?.replace(/\u00a0/g, " ");
		description = description?.replace(/^\[x\]/, "");
		description = description?.replace(/\$(\d+)/g, @modifier(damageBonus, doubleDamage));
		description = description?.replace(/\#(\d+)/g, @modifier(damageBonus, doubleDamage));
		#console.log 'setting description', description

		@description = description

		cls = "card-text textFitAlignVertFlex"
		if entity.tags?.PREMIUM is 1
			cls += " premium"

		# We need to keep the structure textFit will use so that changes to the description are properly propagated
		return <div className={cls} ref={ (div) => @cardText = div; } >
					<span className="textFitted textFitAlignVert">
						<p dangerouslySetInnerHTML={{ __html: description }}></p>
					</span>
				</div>

	updateText: ->
		setTimeout () =>
			rootFontSize = document.getElementById('replayMainArea').style.fontSize.split('px')[0]
			if rootFontSize <= 0
				# console.log '\t[card-text] rootFontSize not defined yet', document.getElementById('replayMainArea')
				setTimeout () =>
					@updateText()
				, 250
			else
				# console.log '[card-text] updating text for', @props.entity.cardID
				domNode = ReactDOM.findDOMNode(@cardText)
				if !domNode
					# console.log '\t[card-text] domNode doesnt exist'
					return
				textBoxWidth = domNode.offsetWidth
				maxFontSize = Math.round(textBoxWidth / 10.0)
				# console.log '\t[card-text] max font sizes', textBoxWidth, maxFontSize, domNode.offsetWidth, domNode
				textFit @cardText, {alignHoriz: true, alignVert: true, alignVertWithFlexbox: true, multiLine: true, minFontSize: 1, maxFontSize: maxFontSize}
				# console.log '\t[card-text] set font size', @cardText.offsetWidth, @cardText.offsetHeight, @cardText.style
		, 0

	componentDidMount: ->
		# console.log '[card-text] component mounted'
		window.addEventListener 'resize', @updateText
		@updateText()

	modifier: (bonus, double) =>
		return (match, part1) =>
			# console.log 'applying modifier for', bonus, double, match, part1
			value = +part1
			if +bonus != 0 or +double != 0
				value += bonus
				value *= Math.pow(2, double)
				# console.log 'updated value', value
				return "*" + value + "*"
			return "" + value

module.exports = CardText
