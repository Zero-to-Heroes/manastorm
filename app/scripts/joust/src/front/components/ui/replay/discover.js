(function() {
  var Card, Discover, React, ReactCSSTransitionGroup, subscribe, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  Card = require('./card');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  subscribe = require('../../../../subscription').subscribe;

  Discover = (function(_super) {
    __extends(Discover, _super);

    function Discover() {
      return Discover.__super__.constructor.apply(this, arguments);
    }

    Discover.prototype.render = function() {
      var cards, hidden;
      if (!(this.props.discoverAction && this.props.discoverController.id === this.props.entity.id)) {
        return null;
      }
      hidden = this.props.isHidden;
      cards = this.props.discoverAction.fullEntities.slice(0, 3).map((function(_this) {
        return function(entity) {
          return React.createElement(Card, {
            "entity": entity,
            "key": entity.id,
            "isHidden": hidden,
            "static": true
          });
        };
      })(this));
      return React.createElement("div", {
        "className": "discover-container"
      }, React.createElement("div", {
        "className": "discover"
      }, cards));
    };

    return Discover;

  })(React.Component);

  module.exports = Discover;

}).call(this);
