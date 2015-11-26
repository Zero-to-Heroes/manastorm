(function() {
  var routes;

  routes = {
    init: function(xmlReplay) {
      var Application, React, Route, Router, createMemoryHistory, externalPlayer, render, router, _ref;
      React = require('react');
      _ref = require('react-router'), Router = _ref.Router, Route = _ref.Route;
      render = require('react-dom').render;
      createMemoryHistory = require('history/lib/createMemoryHistory');
      Application = require('./components/application');
      this.Replay = require('./components/replay');
      routes = React.createElement(Route, {
        "path": "/",
        "component": Application
      }, React.createElement(Route, {
        "path": "/replay",
        "component": this.Replay,
        "replay": xmlReplay
      }));
      console.log('created routes', routes);
      router = React.createElement(Router, {
        "history": createMemoryHistory()
      }, routes);
      externalPlayer = document.getElementById('externalPlayer');
      return render(router, externalPlayer);
    }
  };

  module.exports = routes;

}).call(this);
