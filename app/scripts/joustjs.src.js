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
		// console.log('ext player init in joustjs.src')
	},

	loadReplay: function(replayXml) {
		// console.log('serializing to string', replayXml)
		if (replayXml) {
			var strReplayXml = (new XMLSerializer()).serializeToString(replayXml);
		}
		//console.log('string xml', strReplayXml);

		//require('coffee-react/register');
		var bundle = require('./joust/src/front/bundle.js');
		bundle.init(strReplayXml);

		window.replay.cardUtils = window['parseCardsText']
	},

	reload: function(replayXml) {
		var strReplayXml = (new XMLSerializer()).serializeToString(replayXml);
		// console.log('in reload in joustjs.src', window.replay)
		window.replay.reload(strReplayXml)
	},

	goToTimestamp: function(turnNumber) {
		// console.log('called goToTimestamp in joustjs', turnNumber)
		var regex = /(?:t?)(\d?\d?\do?|mulligan|endgame)/
		var match = turnNumber.match(regex)
		var turn = match[1]
		// console.log('going to turn', turn, match)
		window.replay.pause()
		window.replay.goToFriendlyTurn(turn)
	},

	onTurnChanged: function(callback) {
		// console.log('registering event listener in joustjs src')
		window.replay.onTurnChanged = function(turn) {
			// var turnNumber = turn.turn == 'Mulligan' ? 0 : turn.turn
			// console.log('on turn changed in joustjs.src', turn)
			callback(turn)
		}
	},

	getCurrentTimestamp: function() {
		var turn = window.replay.getCurrentTurn().toLowerCase()
		// console.log('getting current timestamp', turn)
		return turn
	},
	
	getPlayerInfo: function() {
		return window.replay.getPlayerInfo()
	},

	isValid: function() {
		return window.replay.isValid()
	}

}

module.exports = joustjs;