React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
Armor = require './armor'
{subscribe} = require '../../../../subscription'

class HeroPower extends Card

	render: ->
		locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{@props.entity.cardID}.png"

		cls = ""

		if @props.className
			cls += " " + @props.className

		if @props.entity.tags.EXHAUSTED
			cls += " exhausted"
		else 
			style =
				background: "url(#{art}) top left no-repeat"

		if @props.entity.highlighted
			# console.log '\thighlighting', @props.entity.cardID, @props.entity
			cls += " option-on"

		originalCard = @props.cardUtils?.getCard(@props.entity.cardID)
		costCls = "mana-cost"
		originalCost = originalCard.cost
		if @props.entity.tags.COST < originalCost
			costCls += " lower-cost"
		else if @props.entity.tags.COST > originalCost
			costCls += " higher-cost"
		cost = <div className={costCls}>{@props.entity.tags.COST or 0}</div>

		# cost = <div className="mana-cost">2</div>

		link = '<img src="' + art + '">';
		return 	<div className={cls} data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip">
					<div className="game-card" style={style}></div>
					<div className="art"></div>
					{cost}
				</div>

module.exports = HeroPower
