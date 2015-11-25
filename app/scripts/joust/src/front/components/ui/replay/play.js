(function() {
  var Card, Play, React, ReactCSSTransitionGroup, SubscriptionList, zones, _;

  React = require('react');

  Card = require('./card');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  zones = require('../../../../replay/enums.js').zones;

  Play = React.createClass({
    componentDidMount: function() {
      this.subs = new SubscriptionList;
      return this.subs.add(this.props.entity, 'entity-entered-play', (function(_this) {
        return function(_arg) {
          var entity, lastController, lastZone;
          entity = _arg.entity;
          lastZone = entity.getLastZone();
          lastController = entity.getLastController();
          if (lastZone === zones.HAND && (lastController === entity.getController() || !lastController)) {
            _this.setState({
              playing: entity
            });
            return setTimeout((function() {
              return _this.setState({
                playing: null
              });
            }), 1000);
          }
        };
      })(this));
    },
    getInitialState: function() {
      return {
        playing: null
      };
    },
    componentWillUnmount: function() {
      return this.subs.off();
    },
    render: function() {
      var card;
      if (this.state.playing) {
        card = React.createElement(Card, {
          "entity": this.state.playing,
          "key": this.state.playing.id
        });
      } else {
        card = React.createElement("div", {
          "key": -1.
        });
      }
      return React.createElement(ReactCSSTransitionGroup, {
        "component": "div",
        "className": "play",
        "transitionName": "playing",
        "transitionEnterTimeout": 2000.,
        "transitionLeaveTimeout": 500.
      }, card);
    }
  });

  module.exports = Play;

}).call(this);
