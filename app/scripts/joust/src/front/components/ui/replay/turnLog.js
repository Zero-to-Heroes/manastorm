(function() {
  var React, ReactCSSTransitionGroup, SubscriptionList, TurnLog, _;

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  TurnLog = React.createClass({
    componentDidMount: function() {
      this.subs = new SubscriptionList;
      this.replay = this.props.replay;
      this.subs.add(this.replay, 'new-log', (function(_this) {
        return function(action) {};
      })(this));
      return this.logHtml = '';
    },
    render: function() {
      return null;
      return React.createElement("div", {
        "className": "turn-log background-white"
      }, React.createElement("p", {
        "dangerouslySetInnerHTML": {
          __html: this.logHtml
        }
      }));
    },
    buildActionLog: function(action) {
      var card, cardLink, creator, newLog, owner, ownerCard, target;
      card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
      owner = action.owner.name;
      if (!owner) {
        ownerCard = this.entities[action.owner];
        owner = this.replay.buildCardLink(this.replay.getCard(ownerCard.cardID));
      }
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      if (action.secret) {
        if ((cardLink != null ? cardLink.length : void 0) > 0 && action.publicSecret) {
          cardLink += ' -> Secret';
        } else {
          cardLink = 'Secret';
        }
      }
      creator = '';
      if (action.creator) {
        creator = this.replay.buildCardLink(this.replay.cardUtils.getCard(action.creator.cardID)) + ': ';
      }
      newLog = owner + action.type + creator + cardLink;
      if (action.target) {
        target = this.replay.entities[action.target];
        newLog += ' -> ' + this.replay.buildCardLink(this.replay.cardUtils.getCard(target.cardID));
      }
      return newLog;
    }
  });

  module.exports = TurnLog;

}).call(this);
