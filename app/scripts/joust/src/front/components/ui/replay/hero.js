(function() {
  var Card, Hero, React;

  React = require('react');

  Card = require('./card');

  Hero = React.createClass({
    componentDidMount: function() {},
    render: function() {
      var hero, heroPower, hidden;
      if (this.props.entity.tags.MULLIGAN_STATE !== 4) {
        return null;
      }
      hero = this.props.entity.getHero();
      heroPower = this.props.entity.getHeroPower();
      console.log('setting entity', hero, heroPower);
      hidden = false;
      return React.createElement("div", {
        "className": "hero"
      }, React.createElement(Card, {
        "entity": hero,
        "key": hero.id,
        "isHidden": hidden,
        "className": "avatar"
      }), React.createElement(Card, {
        "entity": heroPower,
        "key": heroPower.id,
        "isHidden": hidden,
        "className": "power"
      }));
    }
  });

  module.exports = Hero;

}).call(this);
