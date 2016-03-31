React = require 'react'
{subscribe} = require '../../../../subscription'

class Mana extends React.Component
	componentDidMount: ->
		subscribe @props.entity, 'tag-changed:RESOURCES tag-changed:RESOURCES_USED', =>
			@forceUpdate()

	render: ->
		totalMana = (@props.entity.tags.RESOURCES or 0) 
		totalAvailableMana = totalMana - (@props.entity.tags.RESOURCES_USED or 0)
		totalLocked = (@props.entity.tags.OVERLOAD_LOCKED or 0)
		consumedMana = totalMana - totalAvailableMana - totalLocked
		futureLocked = (@props.entity.tags.OVERLOAD_OWED or 0)

		console.log 'rendering mana', totalMana, totalAvailableMana, totalLocked, futureLocked, @props.entity

		availableMana = <div className="summary">{totalAvailableMana} / {totalMana}</div>

		crystals = []
		if totalAvailableMana > 0
			for i in [1..totalAvailableMana]
				crystal = <div className="mana"></div>
				crystals.push crystal
		if consumedMana > 0
			for i in [1..consumedMana]
				spent = <div className="mana spent"></div>
				crystals.push spent
		if totalLocked > 0
			for i in [1..totalLocked]
				locked = <div className="mana locked"></div>
				crystals.push locked

		if futureLocked > 0
			futures = []	
			if totalMana - futureLocked > 0
				for i in [1..totalMana - futureLocked]
					empty = <div className="mana empty"></div>
					futures.push empty
			for i in [1..futureLocked]
				locked = <div className="mana locked future"></div>
				futures.push locked

		return <div className="mana-container">
			{availableMana}
			<div className="present">{crystals}</div>
			<div className="future">{futures}</div>
		</div>

module.exports = Mana
