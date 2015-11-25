(function() {
  var routes;

  routes = {
    init: function(xmlReplay) {
      var Application, React, Replay, Route, Router, createMemoryHistory, externalPlayer, render, router, _ref;
      React = require('react');
      _ref = require('react-router'), Router = _ref.Router, Route = _ref.Route;
      render = require('react-dom').render;
      createMemoryHistory = require('history/lib/createMemoryHistory');
      Application = require('./components/application');
      Replay = require('./components/replay');
      routes = React.createElement(Route, {
        "path": "/",
        "component": Application
      }, React.createElement(Route, {
        "path": "/replay",
        "component": Replay,
        "replay": xmlReplay
      }));
      router = React.createElement(Router, {
        "history": createMemoryHistory()
      }, routes);
      externalPlayer = document.getElementById('externalPlayer');
      console.log('calling render', render);
      render(router, externalPlayer);
      return console.log('routes.render called');
    }
  };

  module.exports = routes;

}).call(this);
