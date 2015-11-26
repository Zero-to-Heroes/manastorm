bundle = {

	init: (replay) ->
		console.log('in bundle init');

		React = require 'react'
		@routes = require './routes'
		@routes.init(replay)
}

module.exports = bundle;