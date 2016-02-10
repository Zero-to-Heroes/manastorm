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

	goToTimestamp: function(timestamp) {
		var timestampOnlyRegex = /\d?\d:\d?\d?/;
		var time = timestamp.match(timestampOnlyRegex)[0];
		var timeComponents = time.split(':');
		var secs = parseInt(timeComponents[0]) * 60 + parseInt(timeComponents[1]);
		// console.log('going to timestamp', secs, timestamp)
		window.replay.moveToTimestamp(secs);
	},
	getPlayerInfo: function() {
		return window.replay.getPlayerInfo()
	}

}

module.exports = joustjs;