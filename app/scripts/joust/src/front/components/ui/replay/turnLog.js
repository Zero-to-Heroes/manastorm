(function() {
  var $, ActionDisplayLog, PlayerNameDisplayLog, React, ReactCSSTransitionGroup, ReactDOM, SpanDisplayLog, SubscriptionList, TurnDisplayLog, TurnLog, _;

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
        "className": "log-container",
        "id": "turnLog"
      }, this.logs));
    },
    buildActionLog: function(action) {
      var card, cardLink, creator, log, newLog, owner, ownerCard, target;
      if (action.actionType === 'card-draw') {
        log = this.buildCardDrawLog(action);
      } else if (action.actionType === 'secret-revealed') {
        log = this.buildSecretRevealedLog(action);
      } else if (action.actionType === 'played-card-from-hand') {
        log = this.buildPlayedCardFromHandLog(action);
      } else if (action.actionType === 'hero-power') {
        log = this.buildHeroPowerLog(action);
      } else if (action.actionType === 'played-secret-from-hand') {
        log = this.buildPlayedSecretFromHandLog(action);
      } else if (action.actionType === 'power-damage') {
        log = this.buildPowerDamageLog(action);
      } else if (action.actionType === 'power-target') {
        log = this.buildPowerTargetLog(action);
      } else if (action.actionType === 'trigger-fullentity') {
        log = this.buildTriggerFullEntityLog(action);
      } else if (action.actionType === 'summon-weapon') {
        log = this.buildSummonWeaponLog(action);
      } else if (action.actionType === 'attack') {
        log = this.buildAttackLog(action);
      } else if (action.actionType === 'minion-death') {
        log = this.buildMinionDeathLog(action);
      } else if (action.actionType === 'discover') {
        log = this.buildDiscoverLog(action);
      } else if (action.actionType === 'summon-minion') {
        log = this.buildSummonMinionLog(action);
      } else if (action.actionType === 'summon-weapon') {
        log = this.buildSummonWeaponLog(action);
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
      var card, cardLink, drawLog, indent;
      if (action.owner === this.replay.player) {
        card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
        cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      } else {
        cardLink = '<span> 1 card </span>';
      }
      if (action.mainAction) {
        indent = React.createElement("span", {
          "className": "indented-log"
        }, "...and ");
      } else {
        indent = React.createElement(PlayerNameDisplayLog, {
          "active": action.owner === this.replay.player,
          "name": action.owner.name
        });
      }
      drawLog = React.createElement("p", {
        "key": ++this.logIndex
      }, indent, React.createElement("span", null, " draws "), React.createElement(SpanDisplayLog, {
        "newLog": cardLink
      }));
      return drawLog;
    },
    buildPlayedCardFromHandLog: function(action) {
      var card, cardLink, log;
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, React.createElement(PlayerNameDisplayLog, {
        "active": action.owner === this.replay.player,
        "name": action.owner.name
      }), React.createElement("span", null, " plays "), React.createElement("span", {
        "dangerouslySetInnerHTML": {
          __html: cardLink
        }
      }));
      return log;
    },
    buildHeroPowerLog: function(action) {
      var card, cardLink, log;
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, React.createElement(PlayerNameDisplayLog, {
        "active": action.owner === this.replay.player,
        "name": action.owner.name
      }), React.createElement("span", null, " uses "), React.createElement("span", {
        "dangerouslySetInnerHTML": {
          __html: cardLink
        }
      }));
      return log;
    },
    buildPlayedSecretFromHandLog: function(action) {
      var card, cardLink, link, log;
      if ((typeof cardLink !== "undefined" && cardLink !== null ? cardLink.length : void 0) > 0 && action.publicSecret) {
        card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
        cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
        link = React.createElement("span", null, ": ");
      } else {

      }
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, React.createElement(PlayerNameDisplayLog, {
        "active": action.owner === this.replay.player,
        "name": action.owner.name
      }), React.createElement("span", null, " plays a "), React.createElement("span", {
        "className": "secret-revealed"
      }, "Secret "), link, React.createElement("span", {
        "dangerouslySetInnerHTML": {
          __html: cardLink
        }
      }));
      return log;
    },
    buildPowerDamageLog: function(action) {
      var card, cardLink, cardLog, indent, log, target, targetLink;
      if (!action.sameOwnerAsParent) {
        card = action.data ? action.data['cardID'] : '';
        cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
        cardLog = React.createElement("span", {
          "dangerouslySetInnerHTML": {
            __html: cardLink
          }
        });
      }
      if (action.mainAction) {
        indent = React.createElement("span", {
          "className": "indented-log"
        }, "...which ");
      }
      target = this.replay.entities[action.target]['cardID'];
      targetLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(target));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, indent, cardLog, React.createElement("span", null, " deals ", action.amount, " damage to "), React.createElement(SpanDisplayLog, {
        "newLog": targetLink
      }));
      return log;
    },
    buildPowerTargetLog: function(action) {
      var card, cardLink, cardLog, indent, log, target, targetLink;
      if (!action.sameOwnerAsParent) {
        card = action.data ? action.data['cardID'] : '';
        cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
        cardLog = React.createElement("span", {
          "dangerouslySetInnerHTML": {
            __html: cardLink
          }
        });
      }
      if (action.mainAction) {
        indent = React.createElement("span", {
          "className": "indented-log"
        }, "...which ");
      }
      target = this.replay.entities[action.target]['cardID'];
      targetLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(target));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, indent, cardLog, React.createElement("span", null, " targets "), React.createElement(SpanDisplayLog, {
        "newLog": targetLink
      }));
      return log;
    },
    buildTriggerFullEntityLog: function(action) {
      var card, cardLink, creationLog, creations, entity, log, target, targetLink, _i, _len, _ref;
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      console.log('building entity creation log', action);
      creations = [];
      _ref = action.newEntities;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entity = _ref[_i];
        target = entity['cardID'];
        if (target) {
          targetLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(target));
          creationLog = React.createElement("span", {
            "key": ++this.logIndex,
            "className": "list"
          }, React.createElement(SpanDisplayLog, {
            "newLog": cardLink
          }), React.createElement("span", null, " creates "), React.createElement(SpanDisplayLog, {
            "newLog": targetLink
          }));
          creations.push(creationLog);
        }
      }
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, creations);
      return log;
    },
    buildAttackLog: function(action) {
      var card, cardLink, log, target, targetLink;
      card = action.data ? action.data['cardID'] : '';
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      target = this.replay.entities[action.target]['cardID'];
      targetLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(target));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, React.createElement(SpanDisplayLog, {
        "newLog": cardLink
      }), React.createElement("span", null, " attacks "), React.createElement("span", {
        "dangerouslySetInnerHTML": {
          __html: targetLink
        }
      }));
      return log;
    },
    buildMinionDeathLog: function(action) {
      var card, cardLink, log;
      card = this.replay.entities[action.data]['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      return log = React.createElement("p", {
        "key": ++this.logIndex
      }, React.createElement(SpanDisplayLog, {
        "newLog": cardLink
      }), React.createElement("span", null, " dies "));
    },
    buildDiscoverLog: function(action) {
      var card, cardLink, choice, choiceCard, choiceCardLink, choicesCards, log, _i, _len, _ref;
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      choicesCards = [];
      _ref = action.choices;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        choice = _ref[_i];
        choiceCard = choice['cardID'];
        choiceCardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(choiceCard));
        choicesCards.push(React.createElement(SpanDisplayLog, {
          "className": "discovered-card indented-log",
          "newLog": choiceCardLink
        }));
      }
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, React.createElement(SpanDisplayLog, {
        "newLog": cardLink
      }), React.createElement("span", null, " discovers "), choicesCards, React.createElement("span", null));
      return log;
    },
    buildSummonMinionLog: function(action) {
      var card, cardLink, indent, log;
      console.log('buildSummonMinionLog', action);
      if (action.mainAction) {
        indent = React.createElement("span", {
          "className": "indented-log"
        }, "...which");
      } else {
        indent = React.createElement(PlayerNameDisplayLog, {
          "active": action.owner === this.replay.player,
          "name": action.owner.name
        });
      }
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, indent, React.createElement("span", null, " summons "), React.createElement(SpanDisplayLog, {
        "newLog": cardLink
      }));
      return log;
    },
    buildSummonWeaponLog: function(action) {
      var card, cardLink, indent, log;
      if (action.mainAction) {
        indent = React.createElement("span", {
          "className": "indented-log"
        }, "...which");
      } else {
        indent = React.createElement(PlayerNameDisplayLog, {
          "active": action.owner === this.replay.player,
          "name": action.owner.name
        });
      }
      card = action.data['cardID'];
      cardLink = this.replay.buildCardLink(this.replay.cardUtils.getCard(card));
      log = React.createElement("p", {
        "key": ++this.logIndex
      }, indent, React.createElement("span", null, " equips "), React.createElement(SpanDisplayLog, {
        "newLog": cardLink
      }));
      return log;
    },
    buildMulliganLog: function(turn) {
      var card, cardId, cardLink, cardLog, log, logs, mulliganed, _i, _len, _ref, _ref1, _ref2;
      log = React.createElement("p", {
        "className": "turn",
        "key": ++this.logIndex
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
          cardLog = React.createElement("p", {
            "key": ++this.logIndex
          }, React.createElement(PlayerNameDisplayLog, {
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
        cardLog = React.createElement("p", {
          "key": ++this.logIndex
        }, React.createElement(PlayerNameDisplayLog, {
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
      $(node).parent().parent().scrollTo("max");
      return console.log('mounted TurnDisplayLog', node, $(node), $(node).parent());
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
      return $(node).parent().parent().scrollTo("max");
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
      var cls;
      cls = this.props.className;
      cls += " action";
      return React.createElement("p", {
        "className": cls,
        "key": this.index,
        "dangerouslySetInnerHTML": {
          __html: this.props.newLog
        }
      });
    }
  });

  SpanDisplayLog = React.createClass({
    componentDidMount: function() {
      var node;
      this.index = ++this.logIndex;
      node = ReactDOM.findDOMNode(this);
      return $("#turnLog").scrollTo("max");
    },
    render: function() {
      var cls;
      cls = this.props.className;
      cls += " action";
      return React.createElement("span", {
        "className": cls,
        "key": this.index,
        "dangerouslySetInnerHTML": {
          __html: this.props.newLog
        }
      });
    }
  });

  module.exports = TurnLog;

}).call(this);
