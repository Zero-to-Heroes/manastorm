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
      this.callback = __bind(this.callback, this);
      Replay.__super__.constructor.call(this, props);
      this.state = {
        replay: new ReplayPlayer(new HSReplayParser(props.route.replay))
      };
      this.sub = subscribe(this.state.replay, 'players-ready', (function(_this) {
        return function() {
          return _this.callback;
        };
      })(this));
      this.sub = subscribe(this.state.replay, 'moved-timestamp', (function(_this) {
        return function() {
          return setTimeout(_this.callback, 1000);
        };
      })(this));
      console.log('sub', this.sub);
      this.state.replay.init();
    }

    Replay.prototype.componentWillUnmount = function() {
      return this.sub.off();
    };

    Replay.prototype.callback = function() {
      return this.forceUpdate();
    };

    Replay.prototype.render = function() {
      var bottom, playButton, replay, top;
      replay = this.state.replay;
      if (replay.players.length === 2) {
        replay.decidePlayerOpponent();
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
      playButton = React.createElement(Button, {
        "glyph": "play",
        "onClick": this.onClickPlay
      });
      console.log('speed', this.state.replay.getSpeed());
      if (this.state.replay.interval > 0 && this.state.replay.getSpeed() > 0) {
        playButton = React.createElement(Button, {
          "glyph": "pause",
          "onClick": this.onClickPause
        });
      }
      return React.createElement("div", {
        "className": "replay",
        "key": replay.resetCounter
      }, React.createElement("form", {
        "className": "replay__controls padded"
      }, React.createElement(ButtonGroup, null, playButton), React.createElement(Timeline, {
        "replay": replay
      }), React.createElement("div", {
        "className": "playback-speed"
      }, React.createElement("div", {
        "className": "dropup"
      }, React.createElement("button", {
        "className": "btn btn-default dropdown-toggle ng-binding",
        "type": "button",
        "id": "dropdownMenu1",
        "data-toggle": "dropdown",
        "aria-haspopup": "true",
        "aria-expanded": "true"
      }, " ", this.state.replay.getSpeed(), "x ", React.createElement("span", {
        "className": "caret"
      }), " "), React.createElement("ul", {
        "className": "dropdown-menu",
        "aria-labelledby": "dropdownMenu1"
      }, React.createElement("li", null, React.createElement("a", {
        "onClick": this.onClickChangeSpeed.bind(this, 1)
      }, "1x")), React.createElement("li", null, React.createElement("a", {
        "onClick": this.onClickChangeSpeed.bind(this, 2)
      }, "2x")), React.createElement("li", null, React.createElement("a", {
        "onClick": this.onClickChangeSpeed.bind(this, 4)
      }, "4x")), React.createElement("li", null, React.createElement("a", {
        "onClick": this.onClickChangeSpeed.bind(this, 8)
      }, "8x")))))), React.createElement("div", {
        "className": "replay__game"
      }, top, bottom));
    };

    Replay.prototype.onClickPause = function(e) {
      e.preventDefault();
      this.state.replay.pause();
      return this.forceUpdate();
    };

    Replay.prototype.onClickPlay = function(e) {
      e.preventDefault();
      this.state.replay.play();
      return this.forceUpdate();
    };

    Replay.prototype.onClickChangeSpeed = function(speed) {
      console.log('changing speed', speed);
      this.state.replay.changeSpeed(speed);
      return this.forceUpdate();
    };

    return Replay;

  })(React.Component);

  module.exports = Replay;

}).call(this);
