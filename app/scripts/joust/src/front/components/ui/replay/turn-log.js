(function() {
  var React, ReactCSSTransitionGroup, SubscriptionList, TurnLog, _;

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  TurnLog = React.createClass({
    render: function() {
      if (!this.props.show) {
        return null;
      }
      return React.createElement("div", {
        "className": "turn-log"
      });
    }
  });

  module.exports = TurnLog;

}).call(this);
