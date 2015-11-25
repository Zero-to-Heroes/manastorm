(function() {
  var Card, Mulligan, React, subscribe, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  Card = require('./card');

  _ = require('lodash');

  subscribe = require('../../../../subscription').subscribe;

  Mulligan = (function(_super) {
    __extends(Mulligan, _super);

    function Mulligan() {
      return Mulligan.__super__.constructor.apply(this, arguments);
    }

    Mulligan.prototype.componentDidMount = function() {
      return this.sub = subscribe(this.props.entity, 'tag-changed:MULLIGAN_STATE', (function(_this) {
        return function(_arg) {
          var newValue;
          newValue = _arg.newValue;
          return _this.forceUpdate();
        };
      })(this));
    };

    Mulligan.prototype.componentWillUnmount = function() {
      return this.sub.off();
    };

    Mulligan.prototype.render = function() {
      var cards;
      if (!(this.props.entity.tags.MULLIGAN_STATE < 4)) {
        return null;
      }
      cards = this.props.entity.getHand().slice(0, 4).map((function(_this) {
        return function(entity) {
          return React.createElement(Card, {
            "entity": entity,
            "key": entity.id
          });
        };
      })(this));
      return React.createElement("div", {
        "className": "mulligan"
      }, cards);
    };

    return Mulligan;

  })(React.Component);

  module.exports = Mulligan;

}).call(this);
