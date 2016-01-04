(function() {
  var Application, React, Toolbar, Window, _ref;

  React = require('react');

  _ref = require('react-photonkit'), Window = _ref.Window, Toolbar = _ref.Toolbar;

  module.exports = Application = React.createClass({
    render: function() {
      return React.createElement(Window, null, React.createElement(Toolbar, {
        "title": "Joust",
        "className": "title-bar"
      }), React.createElement("div", {
        "className": "application"
      }, this.props.children));
    },
    componentDidMount: function() {
      return this.props.history.push('/replay');
    }
  });

}).call(this);
