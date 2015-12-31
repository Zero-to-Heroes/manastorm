(function() {
  var React, ReactCSSTransitionGroup, SubscriptionList, Target, _;

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  Target = React.createClass({
    componentDidMount: function() {},
    render: function() {
      var alpha, arrowHeight, arrowWidth, containerLeft, containerTop, left, playerEl, sourceDims, style, tanAlpha, targetDims, transform;
      if (!(this.props.source && this.props.target)) {
        return null;
      }
      sourceDims = this.props.source.getDimensions();
      console.log('sourceDims', sourceDims);
      targetDims = this.props.target.getDimensions();
      console.log('targetDims', targetDims);
      arrowHeight = Math.abs(sourceDims.centerY - targetDims.centerY);
      arrowWidth = Math.abs(sourceDims.centerX - targetDims.centerX);
      playerEl = document.getElementById('externalPlayer');
      containerTop = playerEl.getBoundingClientRect().top;
      containerLeft = playerEl.getBoundingClientRect().left;
      console.log(containerTop, containerLeft);
      transform = '';
      if (sourceDims.centerY < targetDims.centerY) {
        transform += 'rotate(180deg)';
      }
      tanAlpha = (sourceDims.centerX - targetDims.centerX) * 1.0 / arrowHeight;
      alpha = Math.atan(tanAlpha) * 180 / Math.PI;
      if (sourceDims.centerY < targetDims.centerY) {
        alpha = -alpha - 180;
      }
      console.log('angle is', alpha);
      transform += 'skewX(' + alpha + 'deg)';
      left = Math.min(sourceDims.centerX, targetDims.centerX) - containerLeft;
      left = left - Math.cos(alpha) * arrowWidth;
      style = {
        height: arrowHeight,
        top: Math.min(sourceDims.centerY, targetDims.centerY) - containerTop,
        left: left,
        transform: transform
      };
      console.log('applying style', style);
      return React.createElement("div", {
        "className": "target",
        "style": style
      });
    }
  });

  module.exports = Target;

}).call(this);
