React = require 'react'
ReactDOM = require 'react-dom'
{subscribe} = require '../../../../subscription'

class Card extends React.Component
	componentDidMount: ->
		tagEvents = 'tag-changed:ATK tag-changed:HEALTH tag-changed:DAMAGE'
		@sub = subscribe @props.entity, tagEvents, =>
			@forceUpdate()

	render: ->
		art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/#{@props.entity.cardID}.png"

		if @props.entity.cardID && !@props.isHidden
			style =
				background: "url(#{art}) top left no-repeat"
				backgroundSize: '100% auto'
			cls = "card"
		else
			style = {}
			cls = "card card--unknown"

		if @props.entity.tags.TAUNT
			cls += " card--taunt"

		if @props.stats
			stats = <div className="card__stats">
				<div className="card__stats__attack">{@props.entity.tags.ATK or 0}</div>
				<div className="card__stats__health">{@props.entity.tags.HEALTH - (@props.entity.tags.DAMAGE or 0)}</div>
			</div>

		return <div className={cls} style={style}>
			{stats}
		</div>

	componentDidUpdate: ->
		#console.log 'updating card dimensions'
		domNode = ReactDOM.findDOMNode(this)
		dimensions = domNode.getBoundingClientRect()
		@centerX = dimensions.left + dimensions.width / 2
		@centerY = dimensions.top + dimensions.height / 2
		#console.log @centerX, @centerY, dimensions, domNode

	getDimensions: ->
		#console.log 'getting dimensions for card', @centerX, @centerY
		return {@centerX, @centerY}

module.exports = Card
