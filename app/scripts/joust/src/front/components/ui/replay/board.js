(function() {
  var Board, Card, React, SubscriptionList, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  Card = require('./card');

  _ = require('lodash');

  SubscriptionList = require('../../../../subscription-list');

  Board = (function(_super) {
    __extends(Board, _super);

    function Board() {
      return Board.__super__.constructor.apply(this, arguments);
    }

    Board.prototype.componentDidMount = function() {
      this.subs = new SubscriptionList;
      return this.subs.add(this.props.entity, 'entity-entered-play', (function(_this) {
        return function(_arg) {
          var entity, entitySub;
          entity = _arg.entity;
          entitySub = _this.subs.add(entity, 'left-play', function() {
            entitySub.off();
            return _this.forceUpdate();
          });
          return _this.forceUpdate();
        };
      })(this));
    };

    Board.prototype.render = function() {
      var cards;
      cards = this.props.entity.getBoard().map(function(entity) {
        return React.createElement(Card, {
          "entity": entity,
          "key": entity.id,
          "stats": true
        });
      });
      return React.createElement("div", {
        "className": "board"
      }, cards);
    };

    return Board;

  })(React.Component);

  module.exports = Board;

}).call(this);
