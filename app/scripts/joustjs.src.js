var joustjs = {

	execute: function(review, text) {
		if (!text) return '';
		if (!window.replay) return text;

		// Get the appropriate timestamp (if any)
		text = window.replay.replaceKeywordsWithTimestamp(text);

		return text;
	},

	init: function(config, review) {
		var replayXml = review.replayXml;
		joustjs.loadReplay(replayXml);
	},

	loadReplay: function(replayXml) {
		// console.log('serializing to string', replayXml)
		var strReplayXml = (new XMLSerializer()).serializeToString(replayXml);
		//console.log('string xml', strReplayXml);

		//require('coffee-react/register');
		var bundle = require('./joust/src/front/bundle.js');
		bundle.init(strReplayXml);

		window.replay.cardUtils = window['parseCardsText']
	},

	goToTimestamp: function(turnNumber) {
		var regex = /\d?\d/;
		var turn = turnNumber.match(regex)[0];
		console.log('going to turn', turn)
		window.replay.goToTurn(turn);
	},
	
	getPlayerInfo: function() {
		return window.replay.getPlayerInfo()
	},

	isValid: function() {
		return window.replay.isValid()
	}

}

module.exports = joustjs;