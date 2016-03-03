React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
Armor = require './armor'
{subscribe} = require '../../../../subscription'

class HeroCard extends Card

	render: ->
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{@props.entity.cardID}.png"

		if @props.entity.cardID && !@props.isHidden
			style =
				background: "url(#{art}) top left no-repeat"
				backgroundSize: '100% auto'
			cls = "game-card"

		if @props.className
			cls += " " + @props.className

		if @props.entity.tags.FROZEN
			overlay = <div className="overlay frozen"></div>
				
		if @props.entity.highlighted
			console.log '\thighlighting', @props.entity.cardID, @props.entity
			cls += " option-on"
			
		if @props.secrets
			show = @props.showSecrets
			secrets = @props.secrets.map (entity) ->
				<Secret entity={entity} key={entity.id} showSecret={show}/>
			#console.log 'rendering secrets', @props.secrets, secrets

		if @props.entity.tags.DAMAGE - @damageTaken > 0
			damage = <span className="damage">{-(@props.entity.tags.DAMAGE - @damageTaken)}</span>

		return 	<div className={cls} style={style}>
					{secrets}
					<Armor entity={@props.entity}/>
					<Health entity={@props.entity}/>
					{damage}
				</div>

module.exports = HeroCard
