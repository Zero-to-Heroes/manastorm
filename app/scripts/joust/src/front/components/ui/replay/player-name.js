(function() {
  var PlayerName, React,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  PlayerName = (function(_super) {
    __extends(PlayerName, _super);

    function PlayerName() {
      return PlayerName.__super__.constructor.apply(this, arguments);
    }

    PlayerName.prototype.render = function() {
      var cls;
      cls = "player-name";
      if (this.props.isActive) {
        cls += " active";
      }
      return React.createElement("div", {
        "className": cls
      }, this.props.entity.name);
    };

    return PlayerName;

  })(React.Component);

  module.exports = PlayerName;

}).call(this);
