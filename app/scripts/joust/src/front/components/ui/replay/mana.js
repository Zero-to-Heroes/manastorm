(function() {
  var Mana, React, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  subscribe = require('../../../../subscription').subscribe;

  Mana = (function(_super) {
    __extends(Mana, _super);

    function Mana() {
      return Mana.__super__.constructor.apply(this, arguments);
    }

    Mana.prototype.componentDidMount = function() {
      return subscribe(this.props.entity, 'tag-changed:RESOURCES tag-changed:RESOURCES_USED', (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
    };

    Mana.prototype.render = function() {
      return React.createElement("div", {
        "className": "mana"
      }, (this.props.entity.tags.RESOURCES || 0) - (this.props.entity.tags.RESOURCES_USED || 0), " \x2F ", this.props.entity.tags.RESOURCES || 0);
    };

    return Mana;

  })(React.Component);

  module.exports = Mana;

}).call(this);
