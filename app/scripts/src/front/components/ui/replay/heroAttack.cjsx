React = require 'react'
SubscriptionList = require '../../../../subscription-list'
{subscribe} = require '../../../../subscription'

class HeroAttack extends React.Component
	componentDidMount: ->
		hero = @props.entity

		@subs = new SubscriptionList
		# @subs.add @props.entity, 'tag-changed:HERO', =>
		# 	@forceUpdate()

	render: ->
		hero = @props.entity
		# console.log 'rendering hero attack?', hero.cardID, hero.tags.ATK, hero
		return null unless hero and hero.tags.ATK

		cls = 'card__stats__attack'

		return <div className={cls}>
			{hero.tags.ATK}
		</div>

module.exports = HeroAttack
