React = require 'react'
Target = require './target'
SubscriptionList = require '../../../../subscription-list'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
_ = require 'lodash'

class TargetManager extends React.Component

	componentWillMount: ->
		# console.log 'will mount target manager'
		@dirty = true

	render: ->
		# console.log 'rendering?', @dirty
		if @dirty
			setTimeout @forceRender, 0
			return null
		
		# console.log 'rendering target manager', @props.replay, @props.components
		replay = @props.replay
		refs = @props.components.refs
		targets = []
		# return null

		# console.log 'retrieving source and targets from', replay.targetSource, replay.targetDestination
		if refs['topBoard'] and refs['bottomBoard'] and refs['topHero'] and refs['bottomHero'] and refs['activeSpell']
			# console.log 'bottomBoard cards', refs['bottomBoard'].getCardsMap()
			allCards = @merge refs['topBoard'].getCardsMap(), refs['bottomBoard'].getCardsMap(), refs['topHero'].getCardsMap(), refs['bottomHero'].getCardsMap(), refs['activeSpell'].getCardsMap()
			# console.log 'merged cards', allCards
			source = @findCard allCards, replay.targetSource

		for targetId in replay.targetDestination
			target = @findCard allCards, targetId
			# console.log 'finding target', target, source
			if target and source
				targetComponent = <Target source={source} target={target} type={replay.targetType} key={'target' + replay.targetSource + '' + targetId}/>
				targets.push targetComponent
				# console.log 'adding target', target, source, targetComponent

		@dirty = true
		return <div>{targets}</div>

	forceRender: =>
		@dirty = false
		# console.log 'forcing render of cards', @dirty
		@forceUpdate()


	findCard: (allCards, cardID) ->
		#console.log 'finding card', topBoardCards, bottomBoardCards, cardID
		if !allCards || !cardID
			return undefined

		#console.log 'topBoard cardsMap', topBoardCards, cardID
		card = allCards[cardID]
		#console.log '\tFound card', card
		return card

	merge: (xs...) ->
	  	if xs?.length > 0
	    	tap {}, (m) -> m[k] = v for k,v of x for x in xs
		tap = (o, fn) -> fn(o); o

module.exports = TargetManager
