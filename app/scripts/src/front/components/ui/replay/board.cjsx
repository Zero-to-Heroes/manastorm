React = require 'react'
Card = require './card'
_ = require 'lodash'
SubscriptionList = require '../../../../subscription-list'

class Board extends React.Component
	componentDidMount: ->
		@subs = new SubscriptionList

		# @subs.add @props.entity, 'entity-entered-play', ({entity}) =>
		# 	entitySub = @subs.add entity, 'left-play', =>
		# 		entitySub.off()
		# 		@forceUpdate()
		# 	@forceUpdate()

	render: ->
		cardsMap = []
		tooltip = @props.tooltips
		replay = @props.replay
		cards = @props.entity.getBoard().map (entity) ->
			cardDiv = <Card entity={entity} key={entity.id} stats={true} ref={entity.id} tooltip={tooltip} cardUtils={replay.cardUtils}/>
			#console.log 'cardsMap before adding entity', cardsMap, entity, cardDiv
			cardsMap.push entity.id
			(cardDiv)
		#console.log 'cardsMap', cardsMap
		@cardsMap = cardsMap
		return <div className="board">
			{cards}
		</div>

	getCardsMap: ->
		result = {}

		#console.log 'building cards map', this.refs
		refs = this.refs
		@cardsMap.forEach (key) ->
			result[key] = refs[key]

		#console.log '\tbuilt cards map', result

		return result

module.exports = Board
