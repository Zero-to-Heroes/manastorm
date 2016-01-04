routes = {
	init: (xmlReplay) ->
		React = require 'react'
		{Router, Route} = require 'react-router'
		{render} = require 'react-dom'
		createMemoryHistory = require('history/lib/createMemoryHistory')

		Application = require './components/application'
		@Replay = require './components/replay'

		routes = <Route path="/" component={Application}>
					<Route path="/replay" component={@Replay} replay={xmlReplay}/>
				</Route>

		#console.log 'created routes', routes
		router = <Router history={createMemoryHistory()}>{routes}</Router>

		externalPlayer = document.getElementById('externalPlayer');
		render(router, externalPlayer)
}

module.exports = routes;