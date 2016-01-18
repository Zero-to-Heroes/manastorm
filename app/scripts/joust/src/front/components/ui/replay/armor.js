(function() {
  var Armor, React, SubscriptionList, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  SubscriptionList = require('../../../../subscription-list');

  subscribe = require('../../../../subscription').subscribe;

  Armor = (function(_super) {
    __extends(Armor, _super);

    function Armor() {
      return Armor.__super__.constructor.apply(this, arguments);
    }

    Armor.prototype.componentDidMount = function() {
      var hero;
      hero = this.props.entity;
      this.subs = new SubscriptionList;
      this.healthSub = subscribe(hero, 'tag-changed:HEALTH tag-changed:DAMAGE', (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
      this.subs.add(this.healthSub);
      return this.subs.add(this.props.entity, 'tag-changed:HERO', (function(_this) {
        return function() {
          _this.healthSub.move(_this.props.entity);
          return _this.forceUpdate();
        };
      })(this));
    };

    Armor.prototype.componentWillUnmount = function() {};

    Armor.prototype.render = function() {
      var cls, hero;
      hero = this.props.entity;
      if (!(hero && hero.tags.ARMOR > 0)) {
        return null;
      }
      cls = 'armor';
      return React.createElement("div", {
        "className": cls
      }, hero.tags.ARMOR);
    };

    return Armor;

  })(React.Component);

  module.exports = Armor;

}).call(this);
