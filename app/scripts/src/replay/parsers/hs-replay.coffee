Stream = require 'string-stream'
sax = require 'sax'
{tagNames, metaTagNames} = require '../enums'

tsToSeconds = (ts) ->
	parts = ts.split(':')
	hours = parseInt(parts[0]) * 60 * 60
	minutes = parseInt(parts[1]) * 60
	seconds = parseFloat(parts[2])

	return hours + minutes + seconds

class HSReplayParser
	constructor: (@xmlReplay) ->
		@entities = {}
		@state = ['root']
		@entityDefinition = {tags: {}}
		@actionDefinition = {}
		@stack = []

	parse: (replay) ->
		if @xmlReplay
			@index = 0
			@replay = replay
			@sax = sax.createStream(true)
			console.log 'starting parsing'

			@sax.on 'opentag', (node) => @onOpenTag(node)
			@sax.on 'closetag', => @onCloseTag()
			@sax.on 'error', (error) =>
				console.error 'error while parsing xml', error

			#@stream = fs.createReadStream(@path).pipe(@sax)
			console.log 'preparing to parse replay'
			@stream = new Stream(@xmlReplay).pipe(@sax)
			console.log 'replay parsed'

	rootState: (node) ->
		node.index = @index++
		#console.log '\tparsing node', node.name, node
		switch node.name
			when 'Game'
				@replay.startTimestamp = tsToSeconds(node.attributes.ts)

			when 'Action', 'Block'
				#console.log 'enqueue action from rootState', node
				#if (node?.attributes?.entity == '70')
					#console.log '\tDebug', node
				@replay.enqueue  'receiveAction', node, tsToSeconds(node.attributes.ts)
				@state.push('action')

			when 'TagChange'
				tag = {
					entity: parseInt(node.attributes.entity)
					tag: tagNames[node.attributes.tag]
					value: parseInt(node.attributes.value)
					parent: @stack[@stack.length - 2]
					index: @index++
				}
				if (!tag.parent.tags)
					tag.parent.tags = []
				tag.parent.tags.push(tag)

				@replay.enqueue 'receiveTagChange', tag

			when 'GameEntity', 'Player', 'FullEntity', 'ShowEntity'
				# console.log '\tpushing game entity to state', node
				@state.push('entity')
				@entityDefinition.id = parseInt(node.attributes.entity or node.attributes.id)
				@entityDefinition.index = @index++
				if node.attributes.cardID
					@entityDefinition.cardID = node.attributes.cardID
					#console.log 'giving name to card', node.attributes.cardID, @entityDefinition.id, @entityDefinition
				if node.attributes.name
					@entityDefinition.name = node.attributes.name

				#@entityDefinition.originalDefinition = @replay.clone(@entityDefinition)
				if node.name == 'ShowEntity'
					@stack[@stack.length - 2].showEntity = @entityDefinition
					# Support for multiple ShowEntity nodes, should replace the standard definition
					@stack[@stack.length - 2].showEntities = @stack[@stack.length - 2].showEntities || []
					@stack[@stack.length - 2].showEntities.push @entityDefinition
					node.parent = @stack[@stack.length - 2]

			when 'Options'
				# console.log 'pushing options', node
				@state.push('options')

			when 'ChosenEntities'
				@chosen =
					entity: node.attributes.entity
					playerID: node.attributes.playerID
					ts: tsToSeconds(node.attributes.ts)
					cards: []
					index: @index++
				@state.push('chosenEntities')

	chosenEntitiesState: (node) ->
		node.index = @index++
		switch node.name
			when 'Choice'
				@chosen.cards.push(node.attributes.entity)

	optionsState: (node) ->
		node.index = @index++
		switch node.name
			when 'Option'
				option = {
					entity: parseInt(node.attributes.entity)
					optionIndex:  parseInt(node.attributes.index)
					type: parseInt(node.attributes.type)
					parent: @stack[@stack.length - 2]
					index: @index++
				}
				if (!option.parent.options)
					option.parent.options = []
				option.parent.options.push(option)

	chosenEntitiesStateClose: (node) ->
		switch node.name
			when 'ChosenEntities'
				@state.pop()
				@replay.enqueue 'receiveChosenEntities', @chosen, @chosen.ts

	optionsStateClose: (node) ->
		switch node.name
			when 'Options'
				@state.pop()
				# console.log 'enqueueing options node', node
				node.debugTs = tsToSeconds(node.attributes.ts)
				@replay.enqueue 'receiveOptions', node, tsToSeconds(node.attributes.ts)

	entityState: (node) ->
		node.index = @index++
		switch node.name
			when 'Tag'
				@entityDefinition.tags[tagNames[parseInt(node.attributes.tag)]] = parseInt(node.attributes.value)

	entityStateClose: (node) ->
		if node.attributes.ts
			ts = tsToSeconds(node.attributes.ts)
		else
			ts = null

		switch node.name
			when 'GameEntity'
				@state.pop()
				@replay.enqueue 'receiveGameEntity', @entityDefinition, ts
				@entityDefinition = {tags: {}}
			when 'Player'
				@state.pop()
				@replay.enqueue 'receivePlayer', @entityDefinition, ts
				@entityDefinition = {tags: {}}
			when 'FullEntity'
				@state.pop()
				@replay.enqueue 'receiveEntity', @entityDefinition, ts
				@entityDefinition = {tags: {}}
			when 'ShowEntity'
				@state.pop()
				@replay.enqueue 'receiveShowEntity', @entityDefinition, ts
				@entityDefinition = {tags: {}}

	actionState: (node) ->
		node.index = @index++
		switch node.name
			when 'ShowEntity', 'FullEntity'
				@state.push('entity')
				@entityDefinition.id = parseInt(node.attributes.entity or node.attributes.id)

				@entityDefinition.attributes = @entityDefinition.attributes or {}
				@entityDefinition.attributes.ts = node.attributes.ts
				@entityDefinition.index = @index++

				if node.attributes.cardID
					@entityDefinition.cardID = node.attributes.cardID
					@replay.mainPlayer @stack[@stack.length - 2].attributes.entity
					#console.log 'giving name to card', node.attributes.cardID, @entityDefinition.id, @entityDefinition
				if node.attributes.name
					@entityDefinition.name = node.attributes.name

				#@entityDefinition.originalDefinition = @replay.clone(@entityDefinition)

				@entityDefinition.parent = @stack[@stack.length - 2]
				if node.name is 'ShowEntity'
					@stack[@stack.length - 2].showEntity = @entityDefinition
					# Support for multiple ShowEntity nodes, should replace the standard definition
					@stack[@stack.length - 2].showEntities = @stack[@stack.length - 2].showEntities || []
					@stack[@stack.length - 2].showEntities.push @entityDefinition
				# Need that to distinguish actions that create tokens
				else 
					@stack[@stack.length - 2].fullEntity = @entityDefinition
					# Support for multiple ShowEntity nodes, should replace the standard definition
					@stack[@stack.length - 2].fullEntities = @stack[@stack.length - 2].fullEntities || []
					@stack[@stack.length - 2].fullEntities.push @entityDefinition

				#if @entityDefinition.id is 72
					#console.log 'parsing bluegill', @entityDefinition, node

			when 'HideEntity'
				@entityDefinition.id = parseInt(node.attributes.entity or node.attributes.id)
				@entityDefinition.index = @index++
				@entityDefinition.parent = @stack[@stack.length - 2]

				if !@entityDefinition.parent.hideEntities
					@entityDefinition.parent.hideEntities = []
				@entityDefinition.parent.hideEntities.push(@entityDefinition.id)


			when 'TagChange'
				tag = {
					entity: parseInt(node.attributes.entity)
					tag: tagNames[node.attributes.tag]
					value: parseInt(node.attributes.value)
					parent: @stack[@stack.length - 2]
					index: @index++
				}
				if (!tag.parent.tags)
					tag.parent.tags = []
				tag.parent.tags.push(tag)
				tag.indent = if tag.parent?.indent then tag.parent.indent + 1 else 1

				#console.log '\tparsing tagchange', @stack[@stack.length - 1], @stack[@stack.length - 2]

				@replay.enqueue 'receiveTagChange', tag

			when 'MetaData'
				if node.attributes.ts
					ts = tsToSeconds(node.attributes.ts)
				else
					ts = null

				#console.error 'parsing MetaData'
				@metaData = {
					meta: metaTagNames[node.attributes.meta || node.attributes.entity]
					data: node.attributes.data
					parent: @stack[@stack.length - 2]
					ts: ts
					index: @index++
				}

				if (!@metaData.parent.meta)
					@metaData.parent.meta = []

				@metaData.parent.meta.push(@metaData)
				@metaData.indent = if @metaData.parent?.indent then @metaData.parent.indent + 1 else 1
				#console.log '\tmetadata', @metaData
				@state.push('metaData')

			when 'Info'
				console.error 'info, shouldnt happen'

			when 'Action', 'Block'
				#@stack[@stack.length - 1].parent = @stack[@stack.length - 2]
				#node.parent = @stack[@stack.length - 2]
				#console.log '\tupdated', @stack[@stack.length - 1]
				node.parent = @stack[@stack.length - 2]
				node.indent = if node.parent?.indent then node.parent.indent + 1 else 1
				node.index = @index++

				#console.log 'parsing action', node

				@state.push('action')
				@replay.enqueue 'receiveAction', node, tsToSeconds(node.attributes.ts)

			when 'Choices'
				@choices =
					entity: parseInt(node.attributes.entity)
					max: node.attributes.max
					min: node.attributes.min
					playerID: node.attributes.playerID
					source: node.attributes.source
					ts: tsToSeconds(node.attributes.ts)
					index: @index++
					cards: []
				@state.push('choices')

		@entityDefinition.indent = if @entityDefinition.parent?.indent then @entityDefinition.parent.indent + 1 else 1

	blockState: (node) ->
		@actionState node

	metaDataState: (node) ->
		#console.log '\tin meta data state', node
		switch node.name
			when 'Info'
				#console.log '\t\tconsidering info node', node
				info = {
					entity: parseInt(node.attributes.id || node.attributes.entity)
					parent: @metaData
				}

				if (!info.parent.info)
					info.parent.info = []

				info.parent.info.push(info)
				#console.log '\t\tinfo', info

	metaDataStateClose: (node) ->
		switch node.name
			when 'MetaData'
				@state.pop()

	choicesState: (node) ->
		switch node.name
			when 'Choice'
				@choices.cards.push(node.attributes.entity)

	choicesStateClose: (node) ->
		switch node.name
			when 'Choices'
				@state.pop()
				@replay.enqueue 'receiveChoices', @choices,  @choices.ts

	actionStateClose: (node) ->
		if node.attributes.ts
			ts = tsToSeconds(node.attributes.ts)
		else
			ts = null
		switch node.name
			when 'Action', 'Block'
				#console.log 'closing action state', node, @entityDefinition
				node = @state.pop()

	blockStateClose: (node) ->
		return actionStateClose node

	onOpenTag: (node) ->
		#console.log 'opening tag', node
		@stack.push(node)
		#console.log 'opening tag', node.name
		#if @stack.length > 1
		#	node.parent = @stack[@stack.length - 2]
		#	node.parent.child = node
		#method = "#{@state[@state.length-1]}State"
		#console.log 'considering node and treatment', node, method, node.attributes.ts
		@["#{@state[@state.length-1]}State"]?(node)

	onCloseTag: () ->
		node = @stack.pop()
		#console.log 'closing tag', node.name
		@["#{@state[@state.length-1]}StateClose"]?(node)




module.exports = HSReplayParser
