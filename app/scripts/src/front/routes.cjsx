routes = {
	init: (xmlReplay) ->
		React = require 'react'
		{Router, Route} = require 'react-router'
		{render} = require 'react-dom'
		createMemoryHistory = require('history/lib/createMemoryHistory')

		Application = require './components/application'
		Replay = require './components/replay'

		routes = <Route path="/" component={Application}>
						<Route path="/replay" component={Replay} replay={xmlReplay}/>
				</Route>

		router = <Router history={createMemoryHistory()}>{routes}</Router>

		externalPlayer = document.getElementById('externalPlayer');
		console.log 'calling render', render
		render(router, externalPlayer)
		console.log 'routes.render called'
		
}

module.exports = routes;