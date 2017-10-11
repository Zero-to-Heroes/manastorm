React = require 'react'
ReactDOM = require 'react-dom'
ReactTooltip = require 'react-tooltip'
Card = require './card'
Secret = require './Secret'

class Secret extends Card

	render: ->
		entity = @props.entity

		style = {}
		cls = "secret "
		if entity.tags.QUEST is 1
			cls += " quest"
		else
			switch entity.tags.CLASS
				when 3
					cls += "hunter"
				when 4
					cls += "mage"
				when 5
					cls += "paladin"

		if @props.className
			cls += " " + @props.className

		if entity.tags.QUEST is 1
			cardRewardId = @getRewardId entity.cardID

			questArt = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/fullcards/en/256/#{entity.cardID}.png"
			rewardArt = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/fullcards/en/256/#{cardRewardId}.png"

			questProgress =
				<div className="quest-progress">
					<img src={questArt} />
					<div className="progress-indicator">
						<div className="status current">{entity.tags.QUEST_PROGRESS or 0}</div>
						<div className="separator">/</div>
						<div className="status total">{entity.tags.QUEST_PROGRESS_TOTAL}</div>
					</div>
					<img src={rewardArt} />
				</div>

			return <div className={cls} key={'secret' + entity.id} data-tip data-for={entity.id} data-place="top" data-effect="solid" data-delay-show="50" data-class="card-tooltip quest-tooltip">
					<ReactTooltip id={"" + entity.id} >
					    {questProgress}
					</ReactTooltip>
				</div>

		else if @props.showSecret
			locale = if window.localStorage.language and window.localStorage.language != 'en' then '/' + window.localStorage.language else ''
			cardArt = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/fullcards/en/256/#{entity.cardID}.png"
			link = '<img src="' + cardArt + '">'
			return <div className={cls} data-tip={link} data-html={true} data-place="right" data-effect="solid" data-delay-show="100" data-class="card-tooltip"></div>
		else
			return <div className={cls} ></div>

	getRewardId: (questId) =>
		switch questId
			when 'UNG_940' # Awaken the Makers
				return 'UNG_940t8'
			when 'UNG_934' # Fire Plume's Heart
				return 'UNG_934t1'
			when 'UNG_116' # Jungle Giants
				return 'UNG_116t'
			when 'UNG_829' # Lakkari Sacrifice
				return 'UNG_829t2'
			when 'UNG_028' # Open the Waygate
				return 'UNG_028t'
			when 'UNG_067' # The Caverns Below
				return 'UNG_067t1'
			when 'UNG_954' # The Last Kaleidosaur
				return 'UNG_954t1'
			when 'UNG_920' # The Marsh Queen
				return 'UNG_920t1'
			when 'UNG_942' # Unite the Murlocs
				return 'UNG_942t'

		throw new Exception('invalid quest: ' + questId)

module.exports = Secret
