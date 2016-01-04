React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
{subscribe} = require '../../../../subscription'

class Secret extends Card

	render: ->

		cls = 'secret'

		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/secrets/#{@props.entity.tags.CLASS}.png"

		style =
			background: "url(#{art}) top left no-repeat"
			backgroundSize: '100% auto'
		cls = "secret"

		if @props.className
			cls += " " + @props.className

		return <div className={cls} style={style}></div>

module.exports = Secret
