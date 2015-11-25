(function() {
  var bundle;

  bundle = {
    init: function(replay) {
      var React, routes;
      console.log('in bundle init');
      React = require('react');
      routes = require('./routes');
      return routes.init(replay);
    }
  };

  module.exports = bundle;

}).call(this);
