(function() {
  var bundle;

  bundle = {
    init: function(replay) {
      var React;
      console.log('in bundle init');
      React = require('react');
      this.routes = require('./routes');
      return this.routes.init(replay);
    }
  };

  module.exports = bundle;

}).call(this);
