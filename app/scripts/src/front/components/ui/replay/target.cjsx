React = require 'react'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

Target = React.createClass

	# getInitialState: ->
	# 	return {hidden: "hidden"}

	# componentWillMount: ->
	# 	console.log 'will mount', Date.now()
	# 	@setState({hidden: ""})
		# that = this
		# @retries = 40
		# setTimeout ->
		# 	that.show()
		# , 20

	# componentWillUnmount: ->
	# 	console.log 'will unmount'
	# 	#console.log 'target component did mount'

	# Need that for going back in the replay, as one of the cards may already be there, while the other isn't
	# show: ->
	# 	@retries--

	# 	that = this
	# 	# console.log 'showing?', @props
	# 	if @props.source or @props.target
	# 		# console.log 'really showing?'
	# 		if @retries > 0 and (!@props.source?.centerX or !@props.target?.centerX)
	# 			# console.log 'waiting to render'
	# 			setTimeout ->
	# 				that.show()
	# 			, 50
	# 		else
	# 			console.log 'yes', @props
	# 			@setState({hidden: ""})

	render: ->
		# console.log 'rendering target?', @props.source, @props.target, @props.source?.getDimensions(), @props.source?.centerX, @props.target?.centerX
		return null unless (@props.source and @props.target and @props.source?.centerX and @props.target?.centerX)
		# console.log 'trying to render target', @props, Date.now()

		sourceDims = @props.source.getDimensions()
		# console.log 'sourceDims', sourceDims
		targetDims = @props.target.getDimensions()
		# console.log 'targetDims', targetDims

		arrowWidth = Math.abs(sourceDims.centerX - targetDims.centerX)
		arrowHeight = Math.abs(sourceDims.centerY - targetDims.centerY)

		playerEl = document.getElementById('externalPlayer')
		containerTop = playerEl.getBoundingClientRect().top
		containerLeft = playerEl.getBoundingClientRect().left

		top = undefined
		height = undefined
		transform = ''

		# If on the same line, it's easy
		# Also, if they are close enough (like Hero Power on self), treat as though on same line, 
		# otherwise the deformation destroys the arrow wompletely
		if Math.abs(sourceDims.centerY - targetDims.centerY) < 10
			# console.log 'Same line interaction'
			left = Math.min(sourceDims.centerX, targetDims.centerX) - containerLeft
			# console.log 'initial left', left
			height = arrowWidth

			# All the height business is because we rotate around the center and not the top
			if sourceDims.centerX < targetDims.centerX
				transform += 'rotate(90deg) '
				#left += height / 2
				#console.log 'new lefts', left
			else
				transform += 'rotate(-90deg) '
			
			# Becuase the initial left is always the one most of the left, we always add to it
			left += height / 2

			top = sourceDims.centerY - containerTop - height / 2
			#console.log 'top', top, containerTop

		else  
			arrowHeight = Math.sqrt(Math.pow(sourceDims.centerY - targetDims.centerY, 2) + Math.pow(sourceDims.centerX - targetDims.centerX, 2))
			# console.log 'arrowHeight', arrowHeight

			angle = Math.atan((targetDims.centerX - sourceDims.centerX) / (sourceDims.centerY - targetDims.centerY))
			# console.log 'angle', angle

			transform += 'rotate(' + angle + 'rad)'

			# If top player attacks, rotate the arrow to have it point down
			if sourceDims.centerY < targetDims.centerY
				transform += 'rotate(180deg) '

			left = Math.min(sourceDims.centerX, targetDims.centerX) + (Math.max(sourceDims.centerX, targetDims.centerX) - Math.min(sourceDims.centerX, targetDims.centerX)) / 2 - containerLeft
			# console.log 'readjusted left', left

			# That's the top of the arrow when not rotated
			top = Math.min(sourceDims.centerY, targetDims.centerY) - containerTop
			# console.log 'top', top

			# Offset for rotation
			if Math.abs(sourceDims.centerX - targetDims.centerX) > 10
				topOffset = arrowHeight / 2 * (1 - Math.sin(angle) / Math.tan(angle))
				top -= topOffset
				# console.log 'offset', topOffset, top

			# Offset to target the center of the element
			# console.log 'sourceDims', @props.source.dimensions
			topOffset = (@props.source?.dimensions?.bottom - @props.source?.dimensions?.top) / 3
			top += topOffset
			height = arrowHeight - 1.5 * topOffset

		cls = "target " + @props.type

		style = {
			height: height
			top: top
			left: left
			transform: transform
		}
		# console.log 'applying style', style
		return <div className={cls} style={style} />

module.exports = Target
