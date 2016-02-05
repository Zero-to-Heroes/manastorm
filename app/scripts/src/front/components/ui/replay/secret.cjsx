React = require 'react'
ReactDOM = require 'react-dom'
Card = require './card'
Secret = require './Secret'
Health = require './health'
{subscribe} = require '../../../../subscription'

class Secret extends Card

	render: ->

		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/secrets/#{@props.entity.tags.CLASS}.png"

		style =
			background: "url(#{art}) top left no-repeat"
			backgroundSize: '100% auto'
		cls = "secret"

		if @props.className
			cls += " " + @props.className

		if @props.showSecret
			locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
			cardArt = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards#{locale}/#{@props.entity.cardID}.png"
			link = '<img src="' + cardArt + '">'
			return <div className={cls} style={style} data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip"></div>
		else
			return <div className={cls} style={style}></div>

module.exports = Secret
