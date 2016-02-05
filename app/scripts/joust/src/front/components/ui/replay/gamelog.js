(function() {
  var GameLog, React, SubscriptionList,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  GameLog = (function(_super) {
    __extends(GameLog, _super);

    function GameLog() {
      return GameLog.__super__.constructor.apply(this, arguments);
    }

    GameLog.prototype.componentDidMount = function() {
      this.subs = new SubscriptionList;
      this.replay = this.props.replay;
      this.logIndex = 0;
      return this.subs.add(this.replay, 'new-log', (function(_this) {
        return function(log) {
          _this.log = log;
          return _this.forceUpdate();
        };
      })(this));
    };

    GameLog.prototype.render = function() {
      return React.createElement("div", {
        "className": "game-log"
      }, this.log, React.createElement("button", {
        "className": "btn btn-default",
        "onClick": this.props.onLogClick
      }, React.createElement("span", null, "Show log")));
    };

    return GameLog;

  })(React.Component);

  module.exports = GameLog;

}).call(this);
