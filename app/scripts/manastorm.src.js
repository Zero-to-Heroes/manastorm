var manastorm = {

	execute: function(review, text) {
		if (!text) return '';
		if (!window.replay) return text;

		// Get the appropriate timestamp (if any)
		text = window.replay.replaceKeywordsWithTimestamp(text);

		return text;
	},

	init: function(config, review, callback, configurationOptions) {
		var replayXml = review.replayXml;
		manastorm.loadReplay(replayXml, callback, configurationOptions);
	},

	initPlayer: function(configurationOptions) {
		var bundle = require('./js/src/front/bundle.js');
		bundle.init('', configurationOptions);
	},

	loadReplay: function(replayXml, callback, configurationOptions) {
		// console.log('serializing to string', replayXml)
		if (replayXml) {
			try {
				var strReplayXml = (new XMLSerializer()).serializeToString(replayXml);
			}
			catch(e) {
				// console.log('couldnt parse as XML', JSON.stringify(e))
				var strReplayXml = replayXml
			}
		}
		//console.log('string xml', strReplayXml);

		//require('coffee-react/register');
		var bundle = require('./js/src/front/bundle.js');
		bundle.init(strReplayXml, configurationOptions, callback);

		window.replay.cardUtils = window['parseCardsText']
	},

	reload: function(replayXml, callback) {
		if (replayXml) {
			try {
				var strReplayXml = (new XMLSerializer()).serializeToString(replayXml);
			}
			catch(e) {
				// console.log('couldnt parse as XML', JSON.stringify(e))
				var strReplayXml = replayXml
			}
		}

		window.replay.reload(strReplayXml, callback)
	},

	goToTimestamp: function(turnNumber) {
		// console.log('going to turn', turnNumber)
		var regex = /(?:t?)(\d?\d?\do?|mulligan|endgame)/
		var match = turnNumber.match(regex)
		var turn = match[1]
		// console.log('going to turn', turn, match)
		window.replay.pause()
		window.replay.goToFriendlyTurn(turn)
	},

	onTurnChanged: function(callback) {
		window.replay.onTurnChanged = function(turn) {
			// console.log('on src.js callback', turn)
			callback(turn)
		}
	},

	getCurrentTimestamp: function() {
		var turn = window.replay.getCurrentTurn()
		return turn
	},

	getTurnLabel: function(turn) {
		return window.replay.getTurnLabel(turn)
	},

	getTurnNumber: function(label) {
		return window.replay.getTurnNumberFromLabel(label)
	},
	
	getPlayerInfo: function() {
		return window.replay.getPlayerInfo()
	},

	isValid: function() {
		return window.replay.isValid()
	}

}

module.exports = manastorm;