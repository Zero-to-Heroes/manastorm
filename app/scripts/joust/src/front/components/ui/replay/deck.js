(function() {
  var Deck, React, subscribe,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  React = require('react');

  subscribe = require('../../../../subscription').subscribe;

  Deck = (function(_super) {
    __extends(Deck, _super);

    function Deck() {
      return Deck.__super__.constructor.apply(this, arguments);
    }

    Deck.prototype.componentDidMount = function() {
      return subscribe(this.props.entity, 'entity-left-deck entity-entered-deck', (function(_this) {
        return function() {
          return _this.forceUpdate();
        };
      })(this));
    };

    Deck.prototype.render = function() {
      return React.createElement("div", {
        "className": "deck"
      }, (this.props.entity.getDeck().length));
    };

    return Deck;

  })(React.Component);

  module.exports = Deck;

}).call(this);
