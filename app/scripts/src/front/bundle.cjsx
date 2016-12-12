bundle = {

	init: (replay, configurationOptions, callback) ->
		 #console.log('in bundle init');

		React = require 'react'
		@routes = require './routes'
		@routes.init(replay, configurationOptions, callback)
}

module.exports = bundle;