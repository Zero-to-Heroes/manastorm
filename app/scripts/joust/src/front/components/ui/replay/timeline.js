(function() {
  var React, Timeline,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  Timeline = (function(_super) {
    __extends(Timeline, _super);

    function Timeline() {
      return Timeline.__super__.constructor.apply(this, arguments);
    }

    Timeline.prototype.componentDidMount = function() {
      return this.int = setInterval(((function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this)), 500);
    };

    Timeline.prototype.componentWillUnmount = function() {};

    Timeline.prototype.render = function() {
      var elapsedMinutes, elapsedSeconds, handleStyle, length, position, remaining, remainingMinutes, remainingSeconds, replay, totalMinutes, totalSeconds;
      replay = this.props.replay;
      this.replay = replay;
      length = replay.getTotalLength();
      totalSeconds = "" + Math.floor(length % 60);
      if (totalSeconds.length < 2) {
        totalSeconds = "0" + totalSeconds;
      }
      totalMinutes = Math.floor(length / 60);
      if (totalMinutes.length < 2) {
        totalMinutes = "0" + totalMinutes;
      }
      position = replay.getElapsed();
      elapsedSeconds = "" + Math.floor(position % 60);
      if (elapsedSeconds.length < 2) {
        elapsedSeconds = "0" + elapsedSeconds;
      }
      elapsedMinutes = Math.floor(position / 60);
      if (elapsedMinutes.length < 2) {
        elapsedMinutes = "0" + elapsedMinutes;
      }
      handleStyle = {
        width: ((position / length) * 100) + '%'
      };
      remaining = Math.floor(length - position);
      remainingSeconds = "" + (remaining % 60);
      if (remainingSeconds.length < 2) {
        remainingSeconds = "0" + remainingSeconds;
      }
      remainingMinutes = Math.floor(remaining / 60);
      return React.createElement("div", {
        "className": "timeline"
      }, React.createElement("div", {
        "className": "timeline-container"
      }, React.createElement("div", {
        "className": "time-display"
      }, elapsedMinutes, ":", elapsedSeconds), React.createElement("div", {
        "className": "scrub-bar",
        "onClick": this.handleClick
      }, React.createElement("div", {
        "className": "slider"
      }, React.createElement("div", {
        "className": "current-time",
        "style": handleStyle
      }))), React.createElement("div", {
        "className": "time-display"
      }, totalMinutes, ":", totalSeconds)));
    };

    Timeline.prototype.handleClick = function(e) {
      var element, left, progression;
      left = 0;
      element = e.target;
      while (element !== null) {
        left += element.offsetLeft || 0;
        element = element.offsetParent;
      }
      progression = (e.clientX - left) / e.target.offsetWidth;
      return this.replay.moveTime(progression);
    };

    return Timeline;

  })(React.Component);

  module.exports = Timeline;

}).call(this);
