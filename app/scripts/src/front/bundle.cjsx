bundle = {

	init: (replay, configurationOptions) ->
		 #console.log('in bundle init');

		React = require 'react'
		@routes = require './routes'
		@routes.init(replay, configurationOptions)
}

module.exports = bundle;