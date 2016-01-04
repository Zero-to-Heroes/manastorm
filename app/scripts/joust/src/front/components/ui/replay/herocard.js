(function() {
  var Card, Health, HeroCard, React, ReactDOM, Secret, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  ReactDOM = require('react-dom');

  Card = require('./card');

  Secret = require('./Secret');

  Health = require('./health');

  subscribe = require('../../../../subscription').subscribe;

  HeroCard = (function(_super) {
    __extends(HeroCard, _super);

    function HeroCard() {
      return HeroCard.__super__.constructor.apply(this, arguments);
    }

    HeroCard.prototype.render = function() {
      var art, cls, secrets, style;
      art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/" + this.props.entity.cardID + ".png";
      if (this.props.entity.cardID && !this.props.isHidden) {
        style = {
          background: "url(" + art + ") top left no-repeat",
          backgroundSize: '100% auto'
        };
        cls = "card";
      }
      if (this.props.className) {
        cls += " " + this.props.className;
      }
      if (this.props.secrets) {
        secrets = this.props.secrets.map(function(entity) {
          return React.createElement(Secret, {
            "entity": entity,
            "key": entity.id
          });
        });
      }
      return React.createElement("div", {
        "className": cls,
        "style": style
      }, secrets, React.createElement(Health, {
        "entity": this.props.entity
      }));
    };

    return HeroCard;

  })(Card);

  module.exports = HeroCard;

}).call(this);
