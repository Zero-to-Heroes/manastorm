React = require 'react'

class HeroAttack extends React.Component
	componentDidMount: ->
		hero = @props.entity


	render: ->
		hero = @props.entity
		# console.log 'rendering hero attack?', hero.cardID, hero.tags.ATK, hero
		return null unless hero and hero.tags.ATK

		cls = 'card__stats__attack'

		return <div className={cls}><span>{hero.tags.ATK}</span></div>

module.exports = HeroAttack
