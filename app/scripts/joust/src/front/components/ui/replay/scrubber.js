(function() {
  var React, Scrubber,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  Scrubber = (function(_super) {
    __extends(Scrubber, _super);

    function Scrubber() {
      return Scrubber.__super__.constructor.apply(this, arguments);
    }

    Scrubber.prototype.componentDidMount = function() {
      return this.int = setInterval(((function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this)), 500);
    };

    Scrubber.prototype.componentWillUnmount = function() {
      return clearInterval(this.int);
    };

    Scrubber.prototype.render = function() {
      var handleStyle, i, length, point, pointStyle, points, position, remaining, remainingMinutes, remainingSeconds, replay, _i, _len, _ref;
      if (!this.props.replay.started) {
        return null;
      }
      replay = this.props.replay;
      length = replay.getTotalLength();
      position = replay.getElapsed();
      handleStyle = {
        width: ((position / length) * 100) + '%'
      };
      points = [];
      _ref = replay.getTimestamps();
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        point = _ref[i];
        pointStyle = {
          left: ((point / length) * 100) + '%'
        };
        points.push(React.createElement("div", {
          "className": "scrubber__point",
          "style": pointStyle,
          "key": i
        }));
      }
      remaining = Math.floor(length - position);
      remainingSeconds = "" + (remaining % 60);
      if (remainingSeconds.length < 2) {
        remainingSeconds = "0" + remainingSeconds;
      }
      remainingMinutes = Math.floor(remaining / 60);
      return React.createElement("div", {
        "className": "scrubber"
      }, React.createElement("div", {
        "className": "scrubber__remaining"
      }, "-", remainingMinutes, ":", remainingSeconds), points, React.createElement("div", {
        "className": "scrubber__elapsed",
        "style": handleStyle
      }));
    };

    return Scrubber;

  })(React.Component);

  module.exports = Scrubber;

}).call(this);
