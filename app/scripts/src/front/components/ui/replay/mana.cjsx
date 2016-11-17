React = require 'react'

class Mana extends React.Component

	render: ->
		# console.log 'rendering mana'
		totalMana = (@props.entity.tags.RESOURCES or 0) 
		totalAvailableMana = totalMana - (@props.entity.tags.RESOURCES_USED or 0)
		totalLocked = (@props.entity.tags.OVERLOAD_LOCKED or 0)
		consumedMana = totalMana - totalAvailableMana - totalLocked
		futureLocked = (@props.entity.tags.OVERLOAD_OWED or 0)

		console.log 'rendering mana', totalMana, totalAvailableMana, totalLocked, futureLocked, @props.entity

		availableMana = <div className="summary"><span>{totalAvailableMana} / {totalMana}</span></div>

		crystals = []
		if totalAvailableMana > 0
			for i in [1..totalAvailableMana]
				key = "mana" + i
				crystal = <div className="mana" key={key}></div>
				crystals.push crystal
		if consumedMana > 0
			for i in [1..consumedMana]
				key = "consumed" + i
				spent = <div className="mana spent" key={key}></div>
				crystals.push spent
		if totalLocked > 0
			for i in [1..totalLocked]
				key = "locked" + i
				locked = <div className="mana locked" key={key}></div>
				crystals.push locked

		if futureLocked > 0
			futures = []	
			if totalMana - futureLocked > 0
				for i in [1..totalMana - futureLocked]
					key = "empty" + i
					empty = <div className="mana empty" key={key}></div>
					futures.push empty
			for i in [1..futureLocked]
				key = "futureLocked" + i
				locked = <div className="mana locked future" key={key}></div>
				futures.push locked

		return <div className="mana-container">
			<div className="browser-compatibility">
				{availableMana}
				<div className="crystals">
					<div className="present">{crystals}</div>
					<div className="future">{futures}</div>
				</div>
			</div>
		</div>

module.exports = Mana
