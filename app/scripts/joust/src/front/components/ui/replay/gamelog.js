(function() {
  var GameLog, React,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  GameLog = (function(_super) {
    __extends(GameLog, _super);

    function GameLog() {
      return GameLog.__super__.constructor.apply(this, arguments);
    }

    GameLog.prototype.componentDidMount = function() {
      return this.int = setInterval(((function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this)), 500);
    };

    GameLog.prototype.render = function() {
      this.replay = this.props.replay;
      return React.createElement("div", {
        "className": "game-log"
      }, React.createElement("p", null, this.replay.turnLog));
    };

    return GameLog;

  })(React.Component);

  module.exports = GameLog;

}).call(this);
