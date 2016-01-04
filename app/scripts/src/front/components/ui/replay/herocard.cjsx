React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
{subscribe} = require '../../../../subscription'

class HeroCard extends Card

	render: ->
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{@props.entity.cardID}.png"

		if @props.entity.cardID && !@props.isHidden
			style =
				background: "url(#{art}) top left no-repeat"
				backgroundSize: '100% auto'
			cls = "card"

		if @props.className
			cls += " " + @props.className

		if @props.secrets
			secrets = @props.secrets.map (entity) ->
				<Secret entity={entity} key={entity.id} />
			#console.log 'rendering secrets', @props.secrets, secrets


		return 	<div className={cls} style={style}>
					{secrets}
					<Health entity={@props.entity}/>
				</div>

module.exports = HeroCard
