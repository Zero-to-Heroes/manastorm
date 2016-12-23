React = require 'react'
Card = require './card'
_ = require 'lodash'

class Board extends React.Component


	render: ->
		# console.log 'rendering board'
		cardsMap = []
		tooltip = @props.tooltips
		replay = @props.replay
		conf = @props.conf
		cards = @props.entity.getBoard().map (entity) ->
			cardDiv = <Card entity={entity} key={entity.id} stats={true} ref={entity.id} tooltip={tooltip} cardUtils={replay.cardUtils} conf={conf}/>
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
