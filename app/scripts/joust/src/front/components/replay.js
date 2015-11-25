(function() {
  var Board, Button, ButtonGroup, Deck, HSReplayParser, Hand, Health, Mana, Mulligan, Play, PlayerName, React, Replay, ReplayPlayer, Timeline, subscribe, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  console.log('in replay');

  React = require('react');

  _ref = require('react-photonkit'), ButtonGroup = _ref.ButtonGroup, Button = _ref.Button;

  ReplayPlayer = require('../../replay/replay-player');

  HSReplayParser = require('../../replay/parsers/hs-replay');

  PlayerName = require('./ui/replay/player-name');

  Hand = require('./ui/replay/hand');

  Deck = require('./ui/replay/deck');

  Mulligan = require('./ui/replay/mulligan');

  Board = require('./ui/replay/board');

  Mana = require('./ui/replay/mana');

  Health = require('./ui/replay/health');

  Timeline = require('./ui/replay/timeline');

  Play = require('./ui/replay/play');

  subscribe = require('../../subscription').subscribe;

  Replay = (function(_super) {
    __extends(Replay, _super);

    function Replay(props) {
      this.onClickPlay = __bind(this.onClickPlay, this);
      this.onClickPause = __bind(this.onClickPause, this);
      Replay.__super__.constructor.call(this, props);
      console.log('initializing replay');
      this.state = {
        replay: new ReplayPlayer(new HSReplayParser(props.route.replay))
      };
      console.log('state', this.state);
      this.sub = subscribe(this.state.replay, 'players-ready', (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
      console.log('sub', this.sub);
      this.state.replay.init();
    }

    Replay.prototype.componentWillUnmount = function() {
      return this.sub.off();
    };

    Replay.prototype.render = function() {
      var bottom, replay, top;
      replay = this.state.replay;
      console.log('rendering in replay', replay);
      if (replay.players.length === 2) {
        console.log('All players are here');
        top = React.createElement("div", {
          "className": "top"
        }, React.createElement(PlayerName, {
          "entity": replay.opponent
        }), React.createElement(Deck, {
          "entity": replay.opponent
        }), React.createElement(Board, {
          "entity": replay.opponent
        }), React.createElement(Mulligan, {
          "entity": replay.opponent
        }), React.createElement(Mana, {
          "entity": replay.opponent
        }), React.createElement(Health, {
          "entity": replay.opponent
        }), React.createElement(Play, {
          "entity": replay.opponent
        }), React.createElement(Hand, {
          "entity": replay.opponent
        }));
        bottom = React.createElement("div", {
          "className": "bottom"
        }, React.createElement(PlayerName, {
          "entity": replay.player
        }), React.createElement(Deck, {
          "entity": replay.player
        }), React.createElement(Board, {
          "entity": replay.player
        }), React.createElement(Mulligan, {
          "entity": replay.player
        }), React.createElement(Mana, {
          "entity": replay.player
        }), React.createElement(Health, {
          "entity": replay.player
        }), React.createElement(Play, {
          "entity": replay.player
        }), React.createElement(Hand, {
          "entity": replay.player
        }));
      }
      console.log('top and bottom are', top, bottom);
      return React.createElement("div", {
        "className": "replay"
      }, React.createElement("form", {
        "className": "replay__controls padded"
      }, React.createElement(ButtonGroup, null, React.createElement(Button, {
        "glyph": "pause",
        "onClick": this.onClickPause
      }), React.createElement(Button, {
        "glyph": "play",
        "onClick": this.onClickPlay
      }), React.createElement(Button, {
        "glyph": "fast-forward",
        "onClick": this.onClickFastForward
      })), React.createElement(Timeline, {
        "replay": replay
      })), React.createElement("div", {
        "className": "replay__game"
      }, top, bottom));
    };

    Replay.prototype.onClickPause = function(e) {
      console.log('pausing', this.state);
      e.preventDefault();
      return this.state.replay.pause();
    };

    Replay.prototype.onClickPlay = function(e) {
      console.log('clicked on play, running', this.state);
      e.preventDefault();
      return this.state.replay.run();
    };

    Replay.prototype.onClickFastForward = function() {};

    return Replay;

  })(React.Component);

  module.exports = Replay;

}).call(this);
