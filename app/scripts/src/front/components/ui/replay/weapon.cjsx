React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
{subscribe} = require '../../../../subscription'

class Weapon extends Card
	componentDidMount: ->

	render: ->
		#console.log 'trying to render weapon', @props.entity
		return null unless @props.entity?.cardID
		#console.log '\trendering weapon', @props.entity

		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{@props.entity.cardID}.png"

		style =
			background: "url(#{art}) top left no-repeat"
			backgroundSize: '100% auto'
		cls = "game-card"

		if @props.className
			cls += " " + @props.className

		stats = <div className="card__stats">
					<div className="card__stats__attack">{@props.entity.tags.ATK or 0}</div>
					<div className="card__stats__health">{@props.entity.tags.DURABILITY - (@props.entity.tags.DAMAGE or 0)}</div>
				</div>

		link = '<img src="' + art + '">';

		return <div className={cls} style={style} data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip">
				{stats}
			</div>

module.exports = Weapon
