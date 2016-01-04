(function() {
  var Card, Hero, HeroCard, React, Weapon;

  React = require('react');

  Card = require('./card');

  HeroCard = require('./herocard');

  Weapon = require('./weapon');

  Hero = React.createClass({
    componentDidMount: function() {},
    render: function() {
      var _ref, _ref1;
      if (this.props.entity.tags.MULLIGAN_STATE !== 4) {
        return null;
      }
      this.hero = this.props.entity.getHero();
      this.heroPower = this.props.entity.getHeroPower();
      this.weapon = this.props.entity.getWeapon();
      this.secrets = this.props.entity.getSecrets();
      return React.createElement("div", {
        "className": "hero"
      }, React.createElement(Weapon, {
        "entity": this.weapon,
        "key": ((_ref = this.weapon) != null ? _ref.id : void 0),
        "ref": ((_ref1 = this.weapon) != null ? _ref1.id : void 0),
        "className": "weapon"
      }), React.createElement(HeroCard, {
        "entity": this.hero,
        "key": this.hero.id,
        "secrets": this.secrets,
        "ref": this.hero.id,
        "className": "avatar"
      }), React.createElement(Card, {
        "entity": this.heroPower,
        "key": this.heroPower.id,
        "ref": this.heroPower.id,
        "className": "power"
      }));
    },
    getCardsMap: function() {
      var result;
      result = {};
      if (!this.hero || !this.heroPower) {
        return result;
      }
      result[this.hero.id] = this.refs[this.hero.id];
      result[this.heroPower.id] = this.refs[this.heroPower.id];
      if (this.weapon) {
        result[this.weapon.id] = this.refs[this.weapon.id];
      }
      return result;
    }
  });

  module.exports = Hero;

}).call(this);
