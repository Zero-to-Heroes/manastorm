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

		style =
			background: "url(#{art}) top left no-repeat"
		cls = "game-card"

		if @props.className
			cls += " " + @props.className

		if @props.entity.highlighted
			# console.log '\thighlighting', @props.entity.cardID, @props.entity
			cls += " option-on"

		cost = <div className="mana-cost">2</div>

		return 	<div className={cls} style={style}>
					{cost}
				</div>

module.exports = HeroPower
