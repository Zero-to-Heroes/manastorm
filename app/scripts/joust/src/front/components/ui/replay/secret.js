(function() {
  var Card, Health, React, ReactDOM, Secret, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  ReactDOM = require('react-dom');

  Card = require('./card');

  Secret = require('./Secret');

  Health = require('./health');

  subscribe = require('../../../../subscription').subscribe;

  Secret = (function(_super) {
    __extends(Secret, _super);

    function Secret() {
      return Secret.__super__.constructor.apply(this, arguments);
    }

    Secret.prototype.render = function() {
      var art, cls, style;
      art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/secrets/" + this.props.entity.tags.CLASS + ".png";
      style = {
        background: "url(" + art + ") top left no-repeat",
        backgroundSize: '100% auto'
      };
      cls = "secret";
      if (this.props.className) {
        cls += " " + this.props.className;
      }
      return React.createElement("div", {
        "className": cls,
        "style": style
      });
    };

    return Secret;

  })(Card);

  module.exports = Secret;

}).call(this);
