(function() {
  var $, ActionDisplayLog, PlayerNameDisplayLog, React, ReactCSSTransitionGroup, ReactDOM, SubscriptionList, TurnDisplayLog, TurnLog, _;

  React = require('react');

  ReactDOM = require('react-dom');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  $ = require('jquery');

  require('jquery.scrollTo');

  _ = require('lodash');

  TurnLog = React.createClass({
    componentDidMount: function() {
      this.subs = new SubscriptionList;
      this.replay = this.props.replay;
      this.logs = [];
      this.logIndex = 0;
      this.subs.add(this.replay, 'new-action', (function(_this) {
        return function(action) {
          var logLine, newLog, _i, _len;
          newLog = _this.buildActionLog(action);
          for (_i = 0, _len = newLog.length; _i < _len; _i++) {
            logLine = newLog[_i];
            _this.logs.push(logLine);
          }
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
      return this.replay.forceReemit();
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
      var card, cardLink, creator, log, newLog, owner, ownerCard, target;
      if (action.actionType === 'card-draw') {
        console.log('adding card draw info', action);
        log = this.buildCardDrawLog(action);
      } else if (action.actionType === 'secret-revealed') {
        log = this.buildSecretRevealedLog(action);
      } else {
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
        log = React.createElement(ActionDisplayLog, {
          "newLog": newLog
        });
      }
      this.replay.notifyNewLog(log);
      return [log];
    },
    buildTurnLog: function(turn) {
      var log;
      if (turn) {
        if (turn.turn === 'Mulligan') {
          log = this.buildMulliganLog(turn);
          return log;
        } else {
          log = React.createElement("p", {
            "className": "turn",
            "key": this.logIndex++
          }, React.createElement(TurnDisplayLog, {
            "turn": turn,
            "active": turn.activePlayer === this.replay.player,
            "name": turn.activePlayer.name
          }));
          this.replay.notifyNewLog(log);
          return [log];
        }
      }
    },
    buildSecretRevealedLog: function(action) {
      var card, cardLink, log, newLog;
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      newLog = '<span><span class="secret-revealed">\tSecret revealed! </span>' + cardLink + '</span>';
      log = React.createElement(ActionDisplayLog, {
        "newLog": newLog
      });
      this.replay.notifyNewLog(log);
      return [log];
    },
    buildCardDrawLog: function(action) {
      var card, cardLink, drawLog;
      if (action.owner === this.replay.player) {
        card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
        cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      } else {
        cardLink = '<span> 1 card </span>';
      }
      drawLog = React.createElement("p", null, React.createElement(PlayerNameDisplayLog, {
        "active": action.owner === this.replay.player,
        "name": action.owner.name
      }), React.createElement("span", null, " draws "), React.createElement("span", {
        "dangerouslySetInnerHTML": {
          __html: cardLink
        }
      }));
      return drawLog;
    },
    buildMulliganLog: function(turn) {
      var card, cardId, cardLink, cardLog, log, logs, mulliganed, _i, _len, _ref, _ref1, _ref2;
      log = React.createElement("p", {
        "className": "turn",
        "key": this.logIndex++
      }, "Mulligan");
      this.replay.notifyNewLog(log);
      logs = [log];
      if (((_ref = turn.playerMulligan) != null ? _ref.length : void 0) > 0) {
        _ref1 = turn.playerMulligan;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          mulliganed = _ref1[_i];
          cardId = this.replay.entities[mulliganed].cardID;
          console.log('cardId', cardId);
          card = this.replay.cardUtils.getCard(cardId);
          console.log('card', card);
          cardLink = this.replay.buildCardLink(card);
          cardLog = React.createElement("p", null, React.createElement(PlayerNameDisplayLog, {
            "active": true,
            "name": this.replay.player.name
          }), React.createElement("span", null, " mulligans "), React.createElement("span", {
            "dangerouslySetInnerHTML": {
              __html: cardLink
            }
          }));
          logs.push(cardLog);
        }
      }
      if (((_ref2 = turn.opponentMulligan) != null ? _ref2.length : void 0) > 0) {
        cardLog = React.createElement("p", null, React.createElement(PlayerNameDisplayLog, {
          "active": false,
          "name": this.replay.opponent.name
        }), " mulligans ", turn.opponentMulligan.length, " cards");
        logs.push(cardLog);
      }
      return logs;
    },
    playerName: function(turn) {
      return React.createElement(PlayerNameDisplayLog, {
        "active": turn.activePlayer === this.replay.player,
        "name": turn.activePlayer.name
      });
    }
  });

  TurnDisplayLog = React.createClass({
    componentDidMount: function() {
      var node;
      this.index = this.logIndex++;
      node = ReactDOM.findDOMNode(this);
      return $(node).parent().scrollTo("max");
    },
    render: function() {
      if (this.props.active) {
        return React.createElement("span", {
          "key": this.index
        }, 'Turn ' + Math.ceil(this.props.turn.turn / 2) + ' - ', React.createElement(PlayerNameDisplayLog, {
          "active": true,
          "name": this.props.name
        }));
      } else {
        return React.createElement("span", {
          "key": this.index
        }, 'Turn ' + Math.ceil(this.props.turn.turn / 2) + 'o - ', React.createElement(PlayerNameDisplayLog, {
          "active": false,
          "name": this.props.name
        }));
      }
    }
  });

  PlayerNameDisplayLog = React.createClass({
    componentDidMount: function() {
      var node;
      this.index = this.logIndex++;
      node = ReactDOM.findDOMNode(this);
      return $(node).parent().scrollTo("max");
    },
    render: function() {
      if (this.props.active) {
        return React.createElement("span", {
          "className": "main-player",
          "key": this.index
        }, this.props.name);
      } else {
        return React.createElement("span", {
          "className": "opponent",
          "key": this.index
        }, this.props.name);
      }
    }
  });

  ActionDisplayLog = React.createClass({
    componentDidMount: function() {
      var node;
      this.index = this.logIndex++;
      node = ReactDOM.findDOMNode(this);
      return $(node).parent().scrollTo("max");
    },
    render: function() {
      return React.createElement("p", {
        "className": "action",
        "key": this.index,
        "dangerouslySetInnerHTML": {
          __html: this.props.newLog
        }
      });
    }
  });

  module.exports = TurnLog;

}).call(this);
