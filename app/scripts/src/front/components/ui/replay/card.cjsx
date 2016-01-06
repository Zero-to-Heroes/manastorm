React = require 'react'
ReactDOM = require 'react-dom'
{subscribe} = require '../../../../subscription'

class Card extends React.Component
	componentDidMount: ->
		tagEvents = 'tag-changed:ATK tag-changed:HEALTH tag-changed:DAMAGE'
		@sub = subscribe @props.entity, tagEvents, =>
			@forceUpdate()

	render: ->
		locale = if window.localStorage.language then window.localStorage.language else ''
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{locale}/#{@props.entity.cardID}.png"

		if @props.entity.cardID && !@props.isHidden
			style =
				background: "url(#{art}) top left no-repeat"
				backgroundSize: '100% auto'
			cls = "game-card"
		else
			style = {}
			cls = "game-card card--unknown"

		if @props.entity.tags.TAUNT
			cls += " card--taunt"

		if @props.className
			cls += " " + @props.className

		if @props.entity.tags.DIVINE_SHIELD
			overlay = <div className="overlay divine-shield"></div>

		if @props.entity.tags.SILENCED
			overlay = <div className="overlay silenced"></div>

		if @props.stats
			healthClass = "card__stats__health"
			if @props.entity.tags.DAMAGE > 0
				healthClass += " damaged"
			stats = <div className="card__stats">
				<div className="card__stats__attack">{@props.entity.tags.ATK or 0}</div>
				<div className={healthClass}>{@props.entity.tags.HEALTH - (@props.entity.tags.DAMAGE or 0)}</div>
			</div>

		return <div className={cls} style={style}>
			{overlay}
			{stats}
		</div>

	componentDidUpdate: ->
		domNode = ReactDOM.findDOMNode(this)
		if domNode
			#console.log 'updating card dimensions'
			dimensions = domNode.getBoundingClientRect()
			@centerX = dimensions.left + dimensions.width / 2
			@centerY = dimensions.top + dimensions.height / 2
		#console.log @centerX, @centerY, dimensions, domNode

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

module.exports = Card
