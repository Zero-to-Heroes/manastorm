React = require 'react'
SubscriptionList = require '../../../../subscription-list'
{subscribe} = require '../../../../subscription'

class Armor extends React.Component
	componentDidMount: ->
		hero = @props.entity


	render: ->
		# console.log 'rendering Armor'
		hero = @props.entity
		return null unless hero and hero.tags.ARMOR > 0
		cls = 'armor'

		return <div className={cls}><span>{hero.tags.ARMOR}</span></div>

module.exports = Armor
