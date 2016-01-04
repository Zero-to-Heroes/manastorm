(function() {
  var Card, Hero, HeroCard, React;

  React = require('react');

  Card = require('./card');

  HeroCard = require('./herocard');

  Hero = React.createClass({
    componentDidMount: function() {},
    render: function() {
      var hidden;
      if (this.props.entity.tags.MULLIGAN_STATE !== 4) {
        return null;
      }
      this.hero = this.props.entity.getHero();
      this.heroPower = this.props.entity.getHeroPower();
      this.secrets = this.props.entity.getSecrets();
      hidden = false;
      return React.createElement("div", {
        "className": "hero"
      }, React.createElement(HeroCard, {
        "entity": this.hero,
        "key": this.hero.id,
        "secrets": this.secrets,
        "isHidden": hidden,
        "ref": this.hero.id,
        "className": "avatar"
      }), React.createElement(Card, {
        "entity": this.heroPower,
        "key": this.heroPower.id,
        "isHidden": hidden,
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
      return result;
    }
  });

  module.exports = Hero;

}).call(this);
