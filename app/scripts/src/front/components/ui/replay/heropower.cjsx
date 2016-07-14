React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
Armor = require './armor'
{subscribe} = require '../../../../subscription'

class HeroPower extends Card

	render: ->
		console.log 'rendering HeroPower'
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{@props.entity.cardID}.png"

		cls = "power"

		if @props.entity.tags.EXHAUSTED
			cls += " exhausted"
		else 
			style =
				backgroundImage: "url(#{art})"

		if @props.entity.highlighted
			# console.log '\thighlighting', @props.entity.cardID, @props.entity
			cls += " option-on"

		originalCard = @props.cardUtils?.getCard(@props.entity.cardID)
		costCls = "mana-cost"
		console.log 'getting cost from', originalCard, @props.entity
		originalCost = originalCard.cost
		tagCost = @props.entity.tags.COST || originalCost
		if tagCost < originalCost
			costCls += " lower-cost"
		else if tagCost > originalCost
			costCls += " higher-cost"
		cost = <div className={costCls}>{tagCost or 0}</div>

		# cost = <div className="mana-cost">2</div>

		link = '<img src="' + art + '">';
		console.log '\theropower rendered'
		return 	<div className="power-container" data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip">
					<div className={cls}>
						<div className="game-card" style={style}></div>
						<div className="art"></div>
						{cost}
					</div>
				</div>

module.exports = HeroPower
