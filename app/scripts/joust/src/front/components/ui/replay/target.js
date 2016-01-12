(function() {
  var React, ReactCSSTransitionGroup, SubscriptionList, Target, _;

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  ReactCSSTransitionGroup = require('react-addons-css-transition-group');

  _ = require('lodash');

  Target = React.createClass({
    componentDidMount: function() {},
    render: function() {
      var alpha, arrowHeight, arrowWidth, containerLeft, containerTop, height, left, playerEl, sourceDims, style, tanAlpha, targetDims, top, transform;
      console.log('trying to render target', this.props);
      if (!(this.props.source && this.props.target)) {
        return null;
      }
      sourceDims = this.props.source.getDimensions();
      console.log('sourceDims', sourceDims);
      targetDims = this.props.target.getDimensions();
      console.log('targetDims', targetDims);
      arrowWidth = Math.abs(sourceDims.centerX - targetDims.centerX);
      arrowHeight = Math.abs(sourceDims.centerY - targetDims.centerY);
      playerEl = document.getElementById('externalPlayer');
      containerTop = playerEl.getBoundingClientRect().top;
      containerLeft = playerEl.getBoundingClientRect().left;
      console.log('containerleft', containerLeft);
      top = void 0;
      height = void 0;
      transform = '';
      if (sourceDims.centerY === targetDims.centerY) {
        console.log('Same line interaction');
        left = Math.min(sourceDims.centerX, targetDims.centerX) - containerLeft;
        console.log('initial left', left);
        height = arrowWidth;
        if (sourceDims.centerX < targetDims.centerX) {
          transform += 'rotate(90deg) ';
          left += height / 2;
        } else {
          transform += 'rotate(-90deg) ';
          left -= height / 2;
        }
        top = sourceDims.centerY - containerTop - height / 2;
        console.log('top', top, containerTop);
      } else {
        if (sourceDims.centerY < targetDims.centerY) {
          transform += 'rotate(180deg) ';
        }
        tanAlpha = (sourceDims.centerX - targetDims.centerX) * 1.0 / arrowHeight;
        alpha = Math.atan(tanAlpha) * 180 / Math.PI;
        if (sourceDims.centerY < targetDims.centerY) {
          alpha = -alpha;
        }
        console.log('angle is', alpha);
        transform += 'skewX(' + alpha + 'deg)';
        alpha = alpha * Math.PI / 180;
        left = Math.min(sourceDims.centerX, targetDims.centerX) - containerLeft;
        console.log('readjusted left', left);
        left = left + Math.tan(Math.abs(alpha)) * arrowHeight / 2;
        console.log('final left', left, alpha, arrowWidth, Math.cos(alpha), Math.cos(alpha) * arrowWidth / 2);
        console.log('final left', left, alpha, arrowHeight, Math.tan(alpha), Math.tan(alpha) * arrowHeight / 2);
        console.log('final top', Math.min(sourceDims.centerY, targetDims.centerY) - containerTop, containerTop);
        top = Math.min(sourceDims.centerY, targetDims.centerY) - containerTop;
        height = arrowHeight;
      }
      style = {
        height: height,
        top: top,
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
