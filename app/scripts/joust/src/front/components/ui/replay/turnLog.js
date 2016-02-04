(function() {
  var PlayerNameDisplayLog, React, ReactCSSTransitionGroup, ReactDOM, SubscriptionList, TurnDisplayLog, TurnLog, _;

  React = require('react');

  ReactDOM = require('react-dom');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  TurnLog = React.createClass({
    componentDidMount: function() {
      this.subs = new SubscriptionList;
      this.replay = this.props.replay;
      this.logs = [];
      this.logIndex = 0;
      this.subs.add(this.replay, 'new-action', (function(_this) {
        return function(action) {
          var newLog;
          newLog = _this.buildActionLog(action);
          _this.logs.push(newLog);
          return _this.forceUpdate();
        };
      })(this));
      this.subs.add(this.replay, 'new-turn', (function(_this) {
        return function(turn) {
          var newLog;
          newLog = _this.buildTurnLog(turn);
          _this.logs.push(newLog);
          return _this.forceUpdate();
        };
      })(this));
      this.subs.add(this.replay, 'reset', (function(_this) {
        return function() {
          _this.logs = [];
          return _this.forceUpdate();
        };
      })(this));
      this.replay.forceReemit();
      this.logHtml = '';
      return console.log('component mounted');
    },
    render: function() {
      if (!this.props.show) {
        return null;
      }
      return React.createElement("div", {
        "className": "turn-log background-white"
      }, React.createElement("div", {
        "className": "log-container"
      }, this.logs));
    },
    buildActionLog: function(action) {
      var card, cardLink, creator, newLog, owner, ownerCard, target;
      card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
      owner = action.owner.name;
      if (!owner) {
        ownerCard = this.replay.entities[action.owner];
        owner = this.replay.buildCardLink(this.replay.cardUtils.getCard(ownerCard.cardID));
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
      return React.createElement("p", {
        "className": "action",
        "key": this.logIndex++,
        "dangerouslySetInnerHTML": {
          __html: newLog
        }
      });
    },
    buildTurnLog: function(turn) {
      if (turn) {
        if (turn.turn === 'Mulligan') {
          return React.createElement("p", {
            "className": "turn",
            "key": this.logIndex++
          }, "Mulligan");
        } else {
          return React.createElement("p", {
            "className": "turn",
            "key": this.logIndex++
          }, React.createElement(TurnDisplayLog, {
            "turn": turn,
            "active": turn.activePlayer === this.replay.player,
            "name": turn.activePlayer.name
          }));
        }
      }
    },
    componentDidUpdate: function() {
      var node;
      node = ReactDOM.findDOMNode(this);
      if (node) {
        return node.scrollTop = node.scrollHeight;
      }
    }
  });

  TurnDisplayLog = React.createClass({
    render: function() {
      if (this.props.active) {
        return React.createElement("span", null, 'Turn ' + Math.ceil(this.props.turn.turn / 2) + ' - ', React.createElement(PlayerNameDisplayLog, {
          "active": true,
          "name": this.props.name
        }));
      } else {
        return React.createElement("span", null, 'Turn ' + Math.ceil(this.props.turn.turn / 2) + 'o - ', React.createElement(PlayerNameDisplayLog, {
          "active": false,
          "name": this.props.name
        }));
      }
    }
  });

  PlayerNameDisplayLog = React.createClass({
    render: function() {
      if (this.props.active) {
        return React.createElement("span", {
          "className": "main-player"
        }, this.props.name);
      } else {
        return React.createElement("span", {
          "className": "opponent"
        }, this.props.name);
      }
    }
  });

  module.exports = TurnLog;

}).call(this);
