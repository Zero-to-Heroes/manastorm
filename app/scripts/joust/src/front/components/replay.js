(function() {
  var Board, Button, ButtonGroup, Deck, GameLog, HSReplayParser, Hand, Health, Hero, Mana, Mulligan, Play, PlayerName, React, Replay, ReplayPlayer, Target, Timeline, subscribe, _, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  console.log('in replay');

  React = require('react');

  _ref = require('react-photonkit'), ButtonGroup = _ref.ButtonGroup, Button = _ref.Button;

  ReplayPlayer = require('../../replay/replay-player');

  HSReplayParser = require('../../replay/parsers/hs-replay');

  PlayerName = require('./ui/replay/player-name');

  Hand = require('./ui/replay/hand');

  Hero = require('./ui/replay/hero');

  Deck = require('./ui/replay/deck');

  Mulligan = require('./ui/replay/mulligan');

  Board = require('./ui/replay/board');

  Mana = require('./ui/replay/mana');

  Health = require('./ui/replay/health');

  Timeline = require('./ui/replay/timeline');

  GameLog = require('./ui/replay/gamelog');

  Play = require('./ui/replay/play');

  Target = require('./ui/replay/target');

  subscribe = require('../../subscription').subscribe;

  _ = require('lodash');

  Replay = (function(_super) {
    var tap;

    __extends(Replay, _super);

    function Replay(props) {
      this.onClickPlay = __bind(this.onClickPlay, this);
      this.goPreviousTurn = __bind(this.goPreviousTurn, this);
      this.goNextTurn = __bind(this.goNextTurn, this);
      this.goPreviousAction = __bind(this.goPreviousAction, this);
      this.goNextAction = __bind(this.goNextAction, this);
      this.callback = __bind(this.callback, this);
      Replay.__super__.constructor.call(this, props);
      this.state = {
        replay: new ReplayPlayer(new HSReplayParser(props.route.replay))
      };
      subscribe(this.state.replay, 'players-ready', (function(_this) {
        return function() {
          return _this.callback;
        };
      })(this));
      subscribe(this.state.replay, 'moved-timestamp', (function(_this) {
        return function() {
          return setTimeout(_this.callback, 500);
        };
      })(this));
      this.state.replay.init();
    }

    Replay.prototype.componentWillUnmount = function() {};

    Replay.prototype.callback = function() {
      return this.forceUpdate();
    };

    Replay.prototype.render = function() {
      var allCards, bottom, replay, source, target, top;
      replay = this.state.replay;
      console.log('rerendering replay');
      if (replay.players.length === 2) {
        top = React.createElement("div", {
          "className": "top"
        }, React.createElement(PlayerName, {
          "entity": replay.opponent
        }), React.createElement(Deck, {
          "entity": replay.opponent
        }), React.createElement(Board, {
          "entity": replay.opponent,
          "ref": "topBoard"
        }), React.createElement(Mulligan, {
          "entity": replay.opponent,
          "isHidden": true
        }), React.createElement(Mana, {
          "entity": replay.opponent
        }), React.createElement(Health, {
          "entity": replay.opponent
        }), React.createElement(Play, {
          "entity": replay.opponent
        }), React.createElement(Hand, {
          "entity": replay.opponent,
          "isHidden": true
        }), React.createElement(Hero, {
          "entity": replay.opponent,
          "ref": "topHero"
        }));
        bottom = React.createElement("div", {
          "className": "bottom"
        }, React.createElement(PlayerName, {
          "entity": replay.player
        }), React.createElement(Deck, {
          "entity": replay.player
        }), React.createElement(Board, {
          "entity": replay.player,
          "ref": "bottomBoard"
        }), React.createElement(Mulligan, {
          "entity": replay.player,
          "isHidden": false
        }), React.createElement(Mana, {
          "entity": replay.player
        }), React.createElement(Health, {
          "entity": replay.player
        }), React.createElement(Play, {
          "entity": replay.player
        }), React.createElement(Hero, {
          "entity": replay.player,
          "ref": "bottomHero"
        }), React.createElement(Hand, {
          "entity": replay.player,
          "isHidden": false
        }));
      } else {
        console.warn('Missing players', replay.players);
      }
      if (this.refs['topBoard'] && this.refs['bottomBoard'] && this.refs['topHero'] && this.refs['bottomHero']) {
        allCards = this.merge(this.refs['topBoard'].getCardsMap(), this.refs['bottomBoard'].getCardsMap(), this.refs['topHero'].getCardsMap(), this.refs['bottomHero'].getCardsMap());
        console.log('merged cards', allCards);
        source = this.findCard(allCards, replay.targetSource);
        target = this.findCard(allCards, replay.targetDestination);
      }
      return React.createElement("div", {
        "className": "replay"
      }, React.createElement("div", {
        "className": "replay__game"
      }, top, bottom, React.createElement(Target, {
        "source": source,
        "target": target
      })), React.createElement("form", {
        "className": "replay__controls padded"
      }, React.createElement(ButtonGroup, null, React.createElement(Button, {
        "glyph": "fast-backward",
        "onClick": this.goPreviousTurn
      }), React.createElement(Button, {
        "glyph": "to-start",
        "onClick": this.goPreviousAction
      }), React.createElement(Button, {
        "glyph": "to-end",
        "onClick": this.goNextAction
      }), React.createElement(Button, {
        "glyph": "fast-forward",
        "onClick": this.goNextTurn
      })), React.createElement(Timeline, {
        "replay": replay
      })), React.createElement(GameLog, {
        "replay": replay
      }));
    };

    Replay.prototype.goNextAction = function(e) {
      e.preventDefault();
      this.state.replay.goNextAction();
      return this.forceUpdate();
    };

    Replay.prototype.goPreviousAction = function(e) {
      e.preventDefault();
      this.state.replay.goPreviousAction();
      return this.forceUpdate();
    };

    Replay.prototype.goNextTurn = function(e) {
      e.preventDefault();
      this.state.replay.goNextTurn();
      return this.forceUpdate();
    };

    Replay.prototype.goPreviousTurn = function(e) {
      e.preventDefault();
      this.state.replay.goPreviousTurn();
      return this.forceUpdate();
    };

    Replay.prototype.onClickPlay = function(e) {
      e.preventDefault();
      this.state.replay.play();
      return this.forceUpdate();
    };

    Replay.prototype.findCard = function(allCards, cardID) {
      var card;
      if (!allCards || !cardID) {
        return void 0;
      }
      card = allCards[cardID];
      return card;
    };

    Replay.prototype.merge = function() {
      var xs;
      xs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if ((xs != null ? xs.length : void 0) > 0) {
        return tap({}, function(m) {
          var k, v, x, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = xs.length; _i < _len; _i++) {
            x = xs[_i];
            _results.push((function() {
              var _results1;
              _results1 = [];
              for (k in x) {
                v = x[k];
                _results1.push(m[k] = v);
              }
              return _results1;
            })());
          }
          return _results;
        });
      }
    };

    tap = function(o, fn) {
      fn(o);
      return o;
    };

    return Replay;

  })(React.Component);

  module.exports = Replay;

}).call(this);
