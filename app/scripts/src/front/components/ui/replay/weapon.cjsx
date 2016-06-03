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
		return <div className="weapon-container"></div> unless @props.entity?.cardID
		#console.log '\trendering weapon', @props.entity

		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{@props.entity.cardID}.png"
		originalCard = @props.cardUtils?.getCard(@props.entity.cardID)

		# console.log 'rendering weapon', @props.entity
		cls = "weapon"
		if @props.entity.tags.CONTROLLER != @props.replay.getActivePlayer().tags.PLAYER_ID
			# console.log 'shearthing', @props.replay.getActivePlayer().tags.PLAYER_ID, @props.entity
			cls += " sheathed"
			style = {}
		else 
			cls += " unsheathed"
			style =
				backgroundImage: "url(#{art})"

		if @props.className
			cls += " " + @props.className

		healthClass = "card__stats__health"
		if @props.entity.tags.DAMAGE > 0
			healthClass += " damaged"


		atkCls = "card__stats__attack"
		if originalCard
			originalAtk = originalCard.attack
			if @props.entity.tags.ATK > originalAtk
				atkCls += " buff"
			else if @props.entity.tags.ATK < originalAtk
				atkCls += " debuff"

		stats = <div className="card__stats">
			<div className={atkCls}><span>{@props.entity.tags.ATK or 0}</span></div>
			<div className={healthClass}><span>{@props.entity.tags.DURABILITY - (@props.entity.tags.DAMAGE or 0)}</span></div>
		</div>

		link = '<img src="' + art + '">';

		return <div className="weapon-container" data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip">
					<div className={cls}>
						<div className="game-card" style={style}></div>
						<div className="art"></div>
						{stats}
					</div>
				</div>

module.exports = Weapon
