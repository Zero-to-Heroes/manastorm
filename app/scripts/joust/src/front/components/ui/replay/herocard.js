(function() {
  var Armor, Card, Health, HeroCard, React, ReactDOM, Secret, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  ReactDOM = require('react-dom');

  Card = require('./card');

  Secret = require('./Secret');

  Health = require('./health');

  Armor = require('./armor');

  subscribe = require('../../../../subscription').subscribe;

  HeroCard = (function(_super) {
    __extends(HeroCard, _super);

    function HeroCard() {
      return HeroCard.__super__.constructor.apply(this, arguments);
    }

    HeroCard.prototype.render = function() {
      var art, cls, overlay, secrets, show, style;
      art = "https://s3.amazonaws.com/com.zerotoheroes/plugins/hearthstone/allCards/" + this.props.entity.cardID + ".png";
      if (this.props.entity.cardID && !this.props.isHidden) {
        style = {
          background: "url(" + art + ") top left no-repeat",
          backgroundSize: '100% auto'
        };
        cls = "game-card";
      }
      if (this.props.className) {
        cls += " " + this.props.className;
      }
      if (this.props.entity.tags.FROZEN) {
        overlay = React.createElement("div", {
          "className": "overlay frozen"
        });
      }
      if (this.props.secrets) {
        show = this.props.showSecrets;
        secrets = this.props.secrets.map(function(entity) {
          return React.createElement(Secret, {
            "entity": entity,
            "key": entity.id,
            "showSecret": show
          });
        });
      }
      return React.createElement("div", {
        "className": cls,
        "style": style
      }, secrets, React.createElement(Armor, {
        "entity": this.props.entity
      }), React.createElement(Health, {
        "entity": this.props.entity
      }));
    };

    return HeroCard;

  })(Card);

  module.exports = HeroCard;

}).call(this);
