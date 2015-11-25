var joustjs = {

	replay: undefined,

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
	}

}

module.exports = joustjs;