React = require 'react'

class CardKeywords extends React.Component

	render: ->
		cardUtils = @props.cardUtils
		entity = @props.entity

		return null unless entity.tags

		keywords = []

		for k,v of entity.tags
			key = 'GLOBAL_KEYWORD_' + k
			console.log '\t' + key, v
			if v and v isnt 0 and cardUtils.keywords[key]
				# console.log '\t\texists'
				name = cardUtils.localizeKeyword(key)
				text = cardUtils.localizeKeyword(key + '_TEXT')
				# console.log '\t\texists', name, text
				statusElement =
					<div className="status" key={'status' + entity.id + key}>
						<h3>{name}</h3>
						<span>{text}</span>
					</div>
				# console.log '\t\tbuild', statusElement
				keywords.push statusElement

		return null unless keywords.length > 0

		return <div className='keywords'>
					<div className="filler"></div>
					{keywords}
				</div>

module.exports = CardKeywords
