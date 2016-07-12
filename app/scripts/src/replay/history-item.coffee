class HistoryItem
	constructor: (@command, @node, @timestamp) ->
		@index = @node.index
		if !@index
			console.error 'no index', @command, @node, @timestamp

	execute: (replay, action) ->
		if @command
			# console.log 'calling command', @command, @node, action, @timestamp
			if action
				# console.log '\t\tcalling command', @command, @node, action, @timestamp
				replay[@command](@node, action)
			else
				replay[@command](@node)
			# replay[command[0]](command[1]...)
		return

	# executeBackInTime: (replay, action) ->
	# 	if @command
	# 		console.log 'calling back in time for command', @command, @node, replay[@command + 'Inverse']
	# 		replay[@command + 'Inverse'](action, @node)

module.exports = HistoryItem
