React = require 'react'
SubscriptionList = require '../../../../subscription-list'
{subscribe} = require '../../../../subscription'

class Health extends React.Component
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
		# console.log 'rendering health'
		hero = @props.entity
		return null unless hero
		cls = 'health'

		if hero.tags.DAMAGE > 0
			cls += ' damaged'

		return <div className={cls}>
			{hero.tags.HEALTH - (hero.tags.DAMAGE or 0)}
		</div>

module.exports = Health
