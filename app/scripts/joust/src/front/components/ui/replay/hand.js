(function() {
  var Card, Hand, React, ReactCSSTransitionGroup, SubscriptionList, _;

  React = require('react');

  Card = require('./card');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  Hand = React.createClass({
    componentDidMount: function() {
      var entity, _i, _len, _ref;
      console.log('Hand did mount');
      this.subs = new SubscriptionList;
      _ref = this.props.entity.getHand();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entity = _ref[_i];
        this.subscribeToEntity(entity);
      }
      this.subs.add(this.props.entity, 'entity-entered-hand', (function(_this) {
        return function(_arg) {
          var entity;
          entity = _arg.entity;
          console.log('entity-entered-hand');
          _this.subscribeToEntity(entity);
          return _this.forceUpdate();
        };
      })(this));
      return this.subs.add(this.props.entity, 'tag-changed:MULLIGAN_STATE', (function(_this) {
        return function() {
          console.log('tag-changed:MULLIGAN_STATE');
          return _this.forceUpdate();
        };
      })(this));
    },
    subscribeToEntity: function(entity) {
      var entitySubs;
      entitySubs = this.subs.add(new SubscriptionList);
      entitySubs.add(entity, 'left-hand', (function(_this) {
        return function() {
          entitySubs.off();
          return _this.forceUpdate();
        };
      })(this));
      return entitySubs.add(entity, 'tag-changed:ZONE_POSITION', (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
    },
    componentWillUnmount: function() {
      console.log('hand will unmount');
      return this.subs.off();
    },
    render: function() {
      var active, cards;
      console.log('rendering hand? ', this.props.entity.tags, this.props.entity.tags.MULLIGAN_STATE);
      if (this.props.entity.tags.MULLIGAN_STATE !== 4) {
        return null;
      }
      console.log('rendering hand');
      active = _.filter(this.props.entity.getHand(), function(entity) {
        return entity.tags.ZONE_POSITION > 0;
      });
      cards = active.map(function(entity) {
        return React.createElement(Card, {
          "entity": entity,
          "key": entity.id
        });
      });
      return React.createElement(ReactCSSTransitionGroup, {
        "component": "div",
        "className": "hand",
        "transitionName": "animate",
        "transitionEnterTimeout": 700.,
        "transitionLeaveTimeout": 700.
      }, cards);
    }
  });

  module.exports = Hand;

}).call(this);
