class HistoryItem
	constructor: (@command, @node, @timestamp) ->
		@index = @node.index
		if !@index
			console.error 'no index', @command, @node, @timestamp

	execute: (replay) ->
		if @command
			# console.log 'calling command', @command, @node, @timestamp, replay[@command]
			replay[@command](@node)
			# replay[command[0]](command[1]...)

		return

module.exports = HistoryItem
