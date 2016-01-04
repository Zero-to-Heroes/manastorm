(function() {
  var Card, React, ReactDOM, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  ReactDOM = require('react-dom');

  subscribe = require('../../../../subscription').subscribe;

  Card = (function(_super) {
    __extends(Card, _super);

    function Card() {
      return Card.__super__.constructor.apply(this, arguments);
    }

    Card.prototype.componentDidMount = function() {
      var tagEvents;
      tagEvents = 'tag-changed:ATK tag-changed:HEALTH tag-changed:DAMAGE';
      return this.sub = subscribe(this.props.entity, tagEvents, (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
    };

    Card.prototype.render = function() {
      var art, cls, overlay, stats, style;
      art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/" + this.props.entity.cardID + ".png";
      if (this.props.entity.cardID && !this.props.isHidden) {
        style = {
          background: "url(" + art + ") top left no-repeat",
          backgroundSize: '100% auto'
        };
        cls = "card";
      } else {
        style = {};
        cls = "card card--unknown";
      }
      if (this.props.entity.tags.TAUNT) {
        cls += " card--taunt";
      }
      if (this.props.className) {
        cls += " " + this.props.className;
      }
      if (this.props.entity.tags.DIVINE_SHIELD) {
        overlay = React.createElement("div", {
          "className": "divine-shield"
        });
      }
      if (this.props.stats) {
        stats = React.createElement("div", {
          "className": "card__stats"
        }, React.createElement("div", {
          "className": "card__stats__attack"
        }, this.props.entity.tags.ATK || 0), React.createElement("div", {
          "className": "card__stats__health"
        }, this.props.entity.tags.HEALTH - (this.props.entity.tags.DAMAGE || 0)));
      }
      return React.createElement("div", {
        "className": cls,
        "style": style
      }, overlay, stats);
    };

    Card.prototype.componentDidUpdate = function() {
      var dimensions, domNode;
      domNode = ReactDOM.findDOMNode(this);
      if (domNode) {
        dimensions = domNode.getBoundingClientRect();
        this.centerX = dimensions.left + dimensions.width / 2;
        return this.centerY = dimensions.top + dimensions.height / 2;
      }
    };

    Card.prototype.getDimensions = function() {
      return {
        centerX: this.centerX,
        centerY: this.centerY
      };
    };

    return Card;

  })(React.Component);

  module.exports = Card;

}).call(this);
