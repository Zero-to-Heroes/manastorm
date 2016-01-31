(function() {
  var React, ReactCSSTransitionGroup, SubscriptionList, Target, _;

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  Target = React.createClass({
    componentDidMount: function() {},
    render: function() {
      var alpha, arrowHeight, arrowWidth, cls, containerLeft, containerTop, height, left, playerEl, sourceDims, style, tanAlpha, targetDims, top, transform;
      if (!(this.props.source && this.props.target)) {
        return null;
      }
      sourceDims = this.props.source.getDimensions();
      targetDims = this.props.target.getDimensions();
      arrowWidth = Math.abs(sourceDims.centerX - targetDims.centerX);
      arrowHeight = Math.abs(sourceDims.centerY - targetDims.centerY);
      playerEl = document.getElementById('externalPlayer');
      containerTop = playerEl.getBoundingClientRect().top;
      containerLeft = playerEl.getBoundingClientRect().left;
      top = void 0;
      height = void 0;
      transform = '';
      if (sourceDims.centerY === targetDims.centerY) {
        left = Math.min(sourceDims.centerX, targetDims.centerX) - containerLeft;
        height = arrowWidth;
        if (sourceDims.centerX < targetDims.centerX) {
          transform += 'rotate(90deg) ';
          left += height / 2;
        } else {
          transform += 'rotate(-90deg) ';
          left -= height / 2;
        }
        top = sourceDims.centerY - containerTop - height / 2;
      } else {
        if (sourceDims.centerY < targetDims.centerY) {
          transform += 'rotate(180deg) ';
        }
        tanAlpha = (sourceDims.centerX - targetDims.centerX) * 1.0 / arrowHeight;
        alpha = Math.atan(tanAlpha) * 180 / Math.PI;
        if (sourceDims.centerY < targetDims.centerY) {
          alpha = -alpha;
        }
        transform += 'skewX(' + alpha + 'deg)';
        alpha = alpha * Math.PI / 180;
        left = Math.min(sourceDims.centerX, targetDims.centerX) - containerLeft;
        left = left + Math.tan(Math.abs(alpha)) * arrowHeight / 2;
        top = Math.min(sourceDims.centerY, targetDims.centerY) - containerTop;
        height = arrowHeight;
      }
      cls = "target " + this.props.type;
      style = {
        height: height,
        top: top,
        left: left,
        transform: transform
      };
      return React.createElement("div", {
        "className": cls,
        "style": style
      });
    }
  });

  module.exports = Target;

}).call(this);
