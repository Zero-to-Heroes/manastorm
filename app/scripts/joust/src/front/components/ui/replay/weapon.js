(function() {
  var Card, Health, React, ReactDOM, Secret, Weapon, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  ReactDOM = require('react-dom');

  Card = require('./card');

  Secret = require('./Secret');

  Health = require('./health');

  subscribe = require('../../../../subscription').subscribe;

  Weapon = (function(_super) {
    __extends(Weapon, _super);

    function Weapon() {
      return Weapon.__super__.constructor.apply(this, arguments);
    }

    Weapon.prototype.componentDidMount = function() {};

    Weapon.prototype.render = function() {
      var art, cls, stats, style, _ref;
      if (!((_ref = this.props.entity) != null ? _ref.cardID : void 0)) {
        return null;
      }
      art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/" + this.props.entity.cardID + ".png";
      style = {
        background: "url(" + art + ") top left no-repeat",
        backgroundSize: '100% auto'
      };
      cls = "card";
      if (this.props.className) {
        cls += " " + this.props.className;
      }
      stats = React.createElement("div", {
        "className": "card__stats"
      }, React.createElement("div", {
        "className": "card__stats__attack"
      }, this.props.entity.tags.ATK || 0), React.createElement("div", {
        "className": "card__stats__health"
      }, this.props.entity.tags.DURABILITY - (this.props.entity.tags.DAMAGE || 0)));
      return React.createElement("div", {
        "className": cls,
        "style": style
      }, stats);
    };

    return Weapon;

  })(Card);

  module.exports = Weapon;

}).call(this);
