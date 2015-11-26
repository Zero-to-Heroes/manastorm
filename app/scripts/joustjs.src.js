var joustjs = {

	init: function(config, review) {
		$.get('/replay.xml', function(replayXml) {
			joustjs.loadReplay(replayXml);
		});
	},

	loadReplay: function(replayXml) {
		console.log('loading replay', replayXml);
		var strReplayXml = (new XMLSerializer()).serializeToString(replayXml);
		// console.log('string xml', strReplayXml);

		//require('coffee-react/register');
		var bundle = require('./joust/src/front/bundle.js');
		bundle.init(strReplayXml);
	},

	goToTimestamp: function(timestamp) {
		var timestampOnlyRegex = /\d?\d:\d?\d(:\d\d\d)?/;
		var time = timestamp.match(timestampOnlyRegex)[0];
		var timeComponents = time.split(':');
		var millis = timeComponents[0] * 60 * 1000 + timeComponents[1] * 1000;
		if (timeComponents[2])
			millis += timeComponents[2];
		window.replay.goToTimestamp(millis);
	}

}

module.exports = joustjs;