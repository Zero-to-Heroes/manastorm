(function() {
  var React, ReactCSSTransitionGroup, SubscriptionList, Turn, _;

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  Turn = React.createClass({
    render: function() {
      var cls;
      if (!this.props.replay) {
        return null;
      }
      cls = 'current-turn';
      if (this.props.active) {
        cls += ' active';
      }
      return React.createElement("div", {
        "className": cls,
        "onClick": this.props.onClick
      }, React.createElement("span", null, this.props.replay.getCurrentTurnString()));
    }
  });

  module.exports = Turn;

}).call(this);
