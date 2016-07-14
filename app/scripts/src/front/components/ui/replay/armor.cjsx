React = require 'react'
SubscriptionList = require '../../../../subscription-list'
{subscribe} = require '../../../../subscription'

class Armor extends React.Component
	componentDidMount: ->
		hero = @props.entity

		# @subs = new SubscriptionList
		# @healthSub = subscribe hero, 'tag-changed:HEALTH tag-changed:DAMAGE', => @forceUpdate()
		# @subs.add @healthSub
		# @subs.add @props.entity, 'tag-changed:HERO', =>
		# 	@healthSub.move @props.entity
		# 	@forceUpdate()

	componentWillUnmount: ->
		#@subs.off()

	render: ->
		console.log 'rendering Armor'
		hero = @props.entity
		return null unless hero and hero.tags.ARMOR > 0
		cls = 'armor'

		return <div className={cls}><span>{hero.tags.ARMOR}</span></div>

module.exports = Armor
