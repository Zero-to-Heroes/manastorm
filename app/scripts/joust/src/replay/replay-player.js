(function() {
  var ActionParser, Entity, EventEmitter, HistoryBatch, Player, ReplayPlayer, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  Entity = require('./entity');

  Player = require('./player');

  HistoryBatch = require('./history-batch');

  ActionParser = require('./action-parser');

  _ = require('lodash');

  EventEmitter = require('events');

  ReplayPlayer = (function(superClass) {
    extend(ReplayPlayer, superClass);

    function ReplayPlayer(parser) {
      this.parser = parser;
      EventEmitter.call(this);
      window.replay = this;
      this.currentTurn = 0;
      this.currentActionInTurn = 0;
      this.cardUtils = window['parseCardsText'];
    }

    ReplayPlayer.prototype.init = function() {
      
      this.entities = {};
      this.players = [];
      this.emit('reset');
      this.game = null;
      this.player = null;
      this.opponent = null;
      this.history = [];
      this.historyPosition = 0;
      this.lastBatch = null;
      this.frequency = 2000;
      this.currentReplayTime = 200;
      this.started = false;
      this.speed = 0;
      this.turns = {
        length: 0
      };
      this.buildCardLink = this.cardUtils.buildCardLink;
      this.parser.parse(this);
      this.goToTimestamp(this.currentReplayTime);
      this.update();
      this.actionParser = new ActionParser(this);
      this.actionParser.populateEntities();
      this.actionParser.parseActions();
      if (parseInt(this.opponent.id) === parseInt(this.mainPlayerId)) {
        this.switchMainPlayer();
      }
      this.emit('game-generated', this);
      this.emit('players-ready');
      return this.goNextAction();
    };

    ReplayPlayer.prototype.autoPlay = function() {
      this.speed = this.previousSpeed || 1;
      if (this.speed > 0) {
        return this.interval = setInterval(((function(_this) {
          return function() {
            return _this.goNextAction();
          };
        })(this)), this.frequency / this.speed);
      }
    };

    ReplayPlayer.prototype.pause = function() {
      if (this.speed > 0) {
        this.previousSpeed = this.speed;
      }
      this.speed = 0;
      return clearInterval(this.interval);
    };

    ReplayPlayer.prototype.changeSpeed = function(speed) {
      this.speed = speed;
      clearInterval(this.interval);
      return this.interval = setInterval(((function(_this) {
        return function() {
          return _this.goNextAction();
        };
      })(this)), this.frequency / this.speed);
    };

    ReplayPlayer.prototype.getCurrentTurnString = function() {
      if (this.turns[this.currentTurn].turn === 'Mulligan') {
        return 'Mulligan';
      } else if (this.turns[this.currentTurn].activePlayer === this.player) {
        return 'Turn ' + Math.ceil(this.turns[this.currentTurn].turn / 2);
      } else {
        return 'Turn ' + Math.ceil(this.turns[this.currentTurn].turn / 2) + 'o';
      }
    };

    ReplayPlayer.prototype.goNextAction = function() {
      var targetTimestamp;
      
      this.newStep();
      this.currentActionInTurn++;
      
      if (this.turns[this.currentTurn] && this.currentActionInTurn <= this.turns[this.currentTurn].actions.length - 1) {
        return this.goToAction();
      } else if (this.turns[this.currentTurn + 1]) {
        
        this.currentTurn++;
        this.currentActionInTurn = -1;
        if (!this.turns[this.currentTurn]) {
          return;
        }
        this.emit('new-turn', this.turns[this.currentTurn]);
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
        return this.goToTimestamp(targetTimestamp);
      }
    };

    ReplayPlayer.prototype.goNextTurn = function() {
      var results, turnWhenCommandIssued;
      if (this.turns[this.currentTurn + 1]) {
        turnWhenCommandIssued = this.currentTurn;
        results = [];
        while (turnWhenCommandIssued === this.currentTurn) {
          results.push(this.goNextAction());
        }
        return results;
      }
    };

    ReplayPlayer.prototype.goPreviousAction = function() {
      var results, targetAction, targetTurn;
      this.newStep();
      if (this.currentActionInTurn === 1) {
        targetTurn = this.currentTurn;
        targetAction = 0;
      } else if (this.currentActionInTurn <= 0 && this.currentTurn <= 2) {
        targetTurn = 0;
        targetAction = 0;
      } else if (this.currentActionInTurn <= 0) {
        targetTurn = this.currentTurn - 1;
        targetAction = this.turns[targetTurn].actions.length - 1;
      } else {
        targetTurn = this.currentTurn;
        targetAction = this.currentActionInTurn - 1;
      }
      this.currentTurn = 0;
      this.currentActionInTurn = -1;
      this.init();
      if (targetTurn === 0 && targetAction === 0) {
        return;
      }
      results = [];
      while (this.currentTurn !== targetTurn || this.currentActionInTurn !== targetAction) {
        results.push(this.goNextAction());
      }
      return results;
    };

    ReplayPlayer.prototype.goPreviousTurn = function() {
      var results, targetTurn;
      this.newStep();
      targetTurn = Math.max(1, this.currentTurn - 1);
      this.currentTurn = 0;
      this.currentActionInTurn = 0;
      this.init();
      results = [];
      while (this.currentTurn !== targetTurn) {
        results.push(this.goNextAction());
      }
      return results;
    };

    ReplayPlayer.prototype.goToAction = function() {
      var action, target, targetTimestamp;
      this.newStep();
      if (this.currentActionInTurn >= 0) {
        
        action = this.turns[this.currentTurn].actions[this.currentActionInTurn];
        this.emit('new-action', action);
        targetTimestamp = 1000 * (action.timestamp - this.startTimestamp) + 1;
        if (action.target) {
          target = this.entities[action.target];
          this.targetSource = action != null ? action.data.id : void 0;
          this.targetDestination = target.id;
          this.targetType = action.actionType;
        }
        return this.goToTimestamp(targetTimestamp);
      }
    };

    ReplayPlayer.prototype.moveTime = function(progression) {
      var target;
      target = this.getTotalLength() * progression;
      return this.moveToTimestamp(target);
    };

    ReplayPlayer.prototype.moveToTimestamp = function(timestamp) {
      var action, i, j, k, l, ref, ref1, ref2, results, targetAction, targetTurn, turn;
      this.pause();
      timestamp += this.startTimestamp;
      
      this.newStep();
      targetTurn = -1;
      targetAction = -1;
      for (i = k = 1, ref = this.turns.length; 1 <= ref ? k <= ref : k >= ref; i = 1 <= ref ? ++k : --k) {
        turn = this.turns[i];
        
        if (turn.timestamp > timestamp) {
          
          break;
        }
        if (!turn.timestamp > timestamp && ((ref1 = turn.actions) != null ? ref1.length : void 0) > 0 && turn.actions[0].timestamp > timestamp) {
          break;
        }
        targetTurn = i;
        if (turn.actions.length > 0) {
          targetAction = -1;
          for (j = l = 0, ref2 = turn.actions.length - 1; 0 <= ref2 ? l <= ref2 : l >= ref2; j = 0 <= ref2 ? ++l : --l) {
            action = turn.actions[j];
            
            if (!action || !action.timestamp || (action != null ? action.timestamp : void 0) > timestamp) {
              break;
            }
            targetAction = j - 1;
          }
        }
      }
      this.currentTurn = 0;
      this.currentActionInTurn = 0;
      this.historyPosition = 0;
      this.init();
      
      if (targetTurn <= 1 || targetAction < -1) {
        return;
      }
      results = [];
      while (this.currentTurn !== targetTurn || this.currentActionInTurn !== targetAction) {
        results.push(this.goNextAction());
      }
      return results;
    };

    ReplayPlayer.prototype.goToTimestamp = function(timestamp) {
      if (timestamp < this.currentReplayTime) {
        
        this.emit('reset');
        this.historyPosition = 0;
        this.init();
      }
      this.currentReplayTime = timestamp;
      this.update();
      return this.emit('moved-timestamp');
    };

    ReplayPlayer.prototype.getActivePlayer = function() {
      var ref;
      return ((ref = this.turns[this.currentTurn]) != null ? ref.activePlayer : void 0) || {};
    };

    ReplayPlayer.prototype.newStep = function() {
      this.targetSource = void 0;
      this.targetDestination = void 0;
      return this.discoverAction = void 0;
    };

    ReplayPlayer.prototype.getTotalLength = function() {
      return this.history[this.history.length - 1].timestamp - this.startTimestamp;
    };

    ReplayPlayer.prototype.getElapsed = function() {
      return this.currentReplayTime / 1000;
    };

    ReplayPlayer.prototype.getTimestamps = function() {
      return _.map(this.history, (function(_this) {
        return function(batch) {
          return batch.timestamp - _this.startTimestamp;
        };
      })(this));
    };

    ReplayPlayer.prototype.replaceKeywordsWithTimestamp = function(text) {
      var matches, mulliganRegex, opoonentTurnRegex, roundRegex, that, turnRegex;
      turnRegex = /(t|T)\d?\d(:|\s|,|\.)/gm;
      opoonentTurnRegex = /(t|T)\d?\do(:|\s|,|\.)/gm;
      mulliganRegex = /(m|M)ulligan(:|\s)/gm;
      roundRegex = /(r|R)\d?\d(:|\s|,|\.)/gm;
      that = this;
      matches = text.match(turnRegex);
      if (matches && matches.length > 0) {
        matches.forEach(function(match) {
          var formattedTimeStamp, inputTurnNumber, timestamp, turn, turnNumber;
          inputTurnNumber = parseInt(match.substring(1, match.length - 1));
          if (that.turns[2].activePlayer === that.player) {
            turnNumber = inputTurnNumber * 2;
          } else {
            turnNumber = inputTurnNumber * 2 + 1;
          }
          turn = that.turns[turnNumber];
          if (turn) {
            timestamp = turn.timestamp + 1;
            formattedTimeStamp = that.formatTimeStamp(timestamp - that.startTimestamp);
            return text = text.replace(match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>');
          }
        });
      }
      matches = text.match(opoonentTurnRegex);
      if (matches && matches.length > 0) {
        matches.forEach(function(match) {
          var formattedTimeStamp, inputTurnNumber, timestamp, turn, turnNumber;
          inputTurnNumber = parseInt(match.substring(1, match.length - 1));
          if (that.turns[2].activePlayer === that.opponent) {
            turnNumber = inputTurnNumber * 2;
          } else {
            turnNumber = inputTurnNumber * 2 + 1;
          }
          turn = that.turns[turnNumber];
          if (turn) {
            timestamp = turn.timestamp + 1;
            formattedTimeStamp = that.formatTimeStamp(timestamp - that.startTimestamp);
            return text = text.replace(match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>');
          }
        });
      }
      matches = text.match(mulliganRegex);
      if (matches && matches.length > 0) {
        matches.forEach(function(match) {
          var formattedTimeStamp, timestamp, turn;
          turn = that.turns[1];
          timestamp = turn.timestamp;
          formattedTimeStamp = that.formatTimeStamp(timestamp - that.startTimestamp);
          return text = text.replace(match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>');
        });
      }
      return text;
    };

    ReplayPlayer.prototype.formatTimeStamp = function(length) {
      var totalMinutes, totalSeconds;
      totalSeconds = "" + Math.floor(length % 60);
      if (totalSeconds.length < 2) {
        totalSeconds = "0" + totalSeconds;
      }
      totalMinutes = Math.floor(length / 60);
      if (totalMinutes.length < 2) {
        totalMinutes = "0" + totalMinutes;
      }
      return totalMinutes + ':' + totalSeconds;
    };

    ReplayPlayer.prototype.update = function() {
      var elapsed, results;
      if (this.currentReplayTime >= this.getTotalLength() * 1000) {
        this.currentReplayTime = this.getTotalLength() * 1000;
      }
      elapsed = this.getElapsed();
      results = [];
      while (this.historyPosition < this.history.length) {
        if (elapsed > this.history[this.historyPosition].timestamp - this.startTimestamp) {
          this.history[this.historyPosition].execute(this);
          results.push(this.historyPosition++);
        } else {
          break;
        }
      }
      return results;
    };

    ReplayPlayer.prototype.receiveGameEntity = function(definition) {
      var entity;
      entity = new Entity(this);
      this.game = this.entities[definition.id] = entity;
      return entity.update(definition);
    };

    ReplayPlayer.prototype.receivePlayer = function(definition) {
      var entity;
      entity = new Player(this);
      this.entities[definition.id] = entity;
      this.players.push(entity);
      entity.update(definition);
      if (entity.tags.CURRENT_PLAYER) {
        return this.player = entity;
      } else {
        return this.opponent = entity;
      }
    };

    ReplayPlayer.prototype.mainPlayer = function(entityId) {
      if (!this.mainPlayerId && (parseInt(entityId) === 2 || parseInt(entityId) === 3)) {
        return this.mainPlayerId = entityId;
      }
    };

    ReplayPlayer.prototype.switchMainPlayer = function() {
      var tempOpponent;
      tempOpponent = this.player;
      this.player = this.opponent;
      this.opponent = tempOpponent;
      this.mainPlayerId = this.player.id;
      return 
    };

    ReplayPlayer.prototype.getController = function(controllerId) {
      if (this.player.tags.CONTROLLER === controllerId) {
        return this.player;
      }
      return this.opponent;
    };

    ReplayPlayer.prototype.receiveEntity = function(definition) {
      var entity;
      if (this.entities[definition.id]) {
        entity = this.entities[definition.id];
      } else {
        entity = new Entity(this);
      }
      this.entities[definition.id] = entity;
      return entity.update(definition);
    };

    ReplayPlayer.prototype.receiveTagChange = function(change) {
      var entity, tags;
      tags = {};
      tags[change.tag] = change.value;
      if (this.entities[change.entity]) {
        entity = this.entities[change.entity];
        return entity.update({
          tags: tags
        });
      } else {
        return entity = this.entities[change.entity] = new Entity({
          id: change.entity,
          tags: tags
        }, this);
      }
    };

    ReplayPlayer.prototype.receiveShowEntity = function(definition) {
      if (this.entities[definition.id]) {
        return this.entities[definition.id].update(definition);
      } else {
        return this.entities[definition.id] = new Entity(definition, this);
      }
    };

    ReplayPlayer.prototype.receiveAction = function(definition) {
      if (definition.isDiscover) {
        this.discoverAction = definition;
        return this.discoverController = this.getController(this.entities[definition.attributes.entity].tags.CONTROLLER);
      }
    };

    ReplayPlayer.prototype.receiveOptions = function() {};

    ReplayPlayer.prototype.receiveChoices = function(choices) {};

    ReplayPlayer.prototype.receiveChosenEntities = function(chosen) {};

    ReplayPlayer.prototype.enqueue = function() {
      var args, command, timestamp;
      timestamp = arguments[0], command = arguments[1], args = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      if (!timestamp && this.lastBatch) {
        this.lastBatch.addCommand([command, args]);
      } else {
        this.lastBatch = new HistoryBatch(timestamp, [command, args]);
        this.history.push(this.lastBatch);
      }
      return this.lastBatch;
    };

    ReplayPlayer.prototype.forceReemit = function() {
      return this.emit('new-turn', this.turns[this.currentTurn]);
    };

    ReplayPlayer.prototype.notifyNewLog = function(log) {
      return this.emit('new-log', log);
    };

    ReplayPlayer.prototype.getPlayerInfo = function() {
      var playerInfo;
      playerInfo = {
        player: {
          'name': this.player.name,
          'class': this.getClass(this.entities[this.player.tags.HERO_ENTITY].cardID)
        },
        opponent: {
          'name': this.opponent.name,
          'class': this.getClass(this.entities[this.opponent.tags.HERO_ENTITY].cardID)
        }
      };
      return playerInfo;
    };

    ReplayPlayer.prototype.getClass = function(cardID) {
      var ref, ref1;
      return (ref = this.cardUtils.getCard(cardID)) != null ? (ref1 = ref.playerClass) != null ? ref1.toLowerCase() : void 0 : void 0;
    };

    return ReplayPlayer;

  })(EventEmitter);

  module.exports = ReplayPlayer;

}).call(this);
