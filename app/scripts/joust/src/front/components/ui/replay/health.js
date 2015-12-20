(function() {
  var Health, React, SubscriptionList, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  subscribe = require('../../../../subscription').subscribe;

  Health = (function(_super) {
    __extends(Health, _super);

    function Health() {
      return Health.__super__.constructor.apply(this, arguments);
    }

    Health.prototype.componentDidMount = function() {
      var hero;
      hero = this.props.entity.getHero();
      this.subs = new SubscriptionList;
      this.healthSub = subscribe(hero, 'tag-changed:HEALTH tag-changed:DAMAGE', (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
      this.subs.add(this.healthSub);
      return this.subs.add(this.props.entity, 'tag-changed:HERO', (function(_this) {
        return function() {
          _this.healthSub.move(_this.props.entity.getHero());
          return _this.forceUpdate();
        };
      })(this));
    };

    Health.prototype.componentWillUnmount = function() {};

    Health.prototype.render = function() {
      var hero;
      hero = this.props.entity.getHero();
      if (!hero) {
        return null;
      }
      return React.createElement("div", {
        "className": "health"
      }, hero.tags.HEALTH - (hero.tags.DAMAGE || 0));
    };

    return Health;

  })(React.Component);

  module.exports = Health;

}).call(this);
