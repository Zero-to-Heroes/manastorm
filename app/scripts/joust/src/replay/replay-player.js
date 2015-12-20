(function() {
  var Entity, EventEmitter, HistoryBatch, Player, ReplayPlayer, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  Entity = require('./entity');

  Player = require('./player');

  HistoryBatch = require('./history-batch');

  _ = require('lodash');

  EventEmitter = require('events');

  ReplayPlayer = (function(superClass) {
    extend(ReplayPlayer, superClass);

    function ReplayPlayer(parser) {
      this.parser = parser;
      EventEmitter.call(this);
      window.replay = this;
      this.turns = {
        length: 0
      };
      this.currentTurn = 0;
      this.currentActionInTurn = 0;
    }

    ReplayPlayer.prototype.init = function() {
      this.entities = {};
      this.players = [];
      this.game = null;
      this.player = null;
      this.opponent = null;
      this.history = [];
      this.historyPosition = 0;
      this.lastBatch = null;
      this.startTimestamp = null;
      this.currentReplayTime = 200;
      this.started = false;
      this.turnLog = '';
      this.cardUtils = window['parseCardsText'];
      console.log('cardUtils', this.cardUtils);
      this.parser.parse(this);
      return this.finalizeInit();
    };

    ReplayPlayer.prototype.start = function(timestamp) {
      this.startTimestamp = timestamp;
      return this.started = true;
    };

    ReplayPlayer.prototype.play = function() {
      return this.goToTimestamp(this.currentReplayTime);
    };

    ReplayPlayer.prototype.goNextAction = function() {
      var action, card, targetTimestamp;
      this.turnLog = '';
      console.log('going to next action', this.currentActionInTurn);
      this.currentActionInTurn++;
      targetTimestamp = this.getTotalLength() * 1000;
      if (this.turns[this.currentTurn] && this.currentActionInTurn <= this.turns[this.currentTurn].actions.length - 1) {
        action = this.turns[this.currentTurn].actions[this.currentActionInTurn];
        targetTimestamp = 1000 * (action.timestamp - this.startTimestamp) + 1;
        console.log('executing action', action, action.data);
        card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
        this.turnLog = action.owner.name + action.type + this.cardUtils.localizeName(this.cardUtils.getCard(card));
        if (action.target) {
          this.turnLog += ' -> ' + this.cardUtils.localizeName(this.cardUtils.getCard(action.target.cardID));
        }
        console.log(this.turnLog);
        this.goToTimestamp(targetTimestamp);
        return this.update();
      } else {
        console.log('going directly to next turn');
        return this.goNextTurn();
      }
    };

    ReplayPlayer.prototype.goPreviousAction = function() {
      this.turnLog = '';
      return console.log('going to previous action');
    };

    ReplayPlayer.prototype.goNextTurn = function() {
      var targetTimestamp;
      this.currentActionInTurn = 0;
      this.currentTurn++;
      this.turnLog = 't' + this.currentTurn + ': ' + this.turns[this.currentTurn].activePlayer.name;
      targetTimestamp = this.getTotalLength() * 1000;
      if (this.currentTurn <= this.turns.length) {
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
      }
      this.goToTimestamp(targetTimestamp);
      return this.update();
    };

    ReplayPlayer.prototype.goPreviousTurn = function() {
      var targetTimestamp;
      this.currentActionInTurn = 0;
      this.currentTurn--;
      this.turnLog = 't' + this.currentTurn + ': ' + this.turns[this.currentTurn].activePlayer.name;
      targetTimestamp = this.getTotalLength() * 1000;
      if (this.currentTurn <= 0) {
        targetTimestamp = 0;
        this.currentTurn = 0;
      } else if (this.currentTurn <= this.turns.length) {
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
      }
      this.goToTimestamp(targetTimestamp);
      return this.update();
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

    ReplayPlayer.prototype.moveTime = function(progression) {
      var target;
      target = this.getTotalLength() * progression * 1000;
      return this.goToTimestamp(target);
    };

    ReplayPlayer.prototype.goToTimestamp = function(timestamp) {
      console.log('going to timestamp', timestamp);
      if (timestamp < this.currentReplayTime) {
        this.currentReplayTime = timestamp;
        this.historyPosition = 0;
        this.init();
      }
      this.start(this.startTimestamp);
      this.currentReplayTime = timestamp;
      this.update();
      return this.emit('moved-timestamp');
    };

    ReplayPlayer.prototype.update = function() {
      var elapsed;
      if (this.currentReplayTime >= this.getTotalLength() * 1000) {
        this.currentReplayTime = this.getTotalLength() * 1000;
      }
      elapsed = this.getElapsed();
      while (this.historyPosition < this.history.length) {
        if (elapsed > this.history[this.historyPosition].timestamp - this.startTimestamp) {
          this.history[this.historyPosition].execute(this);
          this.historyPosition++;
        } else {
          break;
        }
      }
      return console.log('stopped at history', this.history[this.historyPosition].timestamp, elapsed);
    };

    ReplayPlayer.prototype.receiveGameEntity = function(definition) {
      var entity;
      console.log('receiving game entity', definition);
      entity = new Entity(this);
      this.game = this.entities[definition.id] = entity;
      return entity.update(definition);
    };

    ReplayPlayer.prototype.receivePlayer = function(definition) {
      var entity;
      console.log('receiving player', definition);
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

    ReplayPlayer.prototype.finalizeInit = function() {
      var action, actionIndex, batch, command, currentPlayer, currentTurnNumber, entityTag, i, j, k, l, len, len1, len2, len3, m, n, playedCard, playerIndex, players, ref, ref1, ref2, ref3, ref4, tag, tagValue, tempOpponent, turnNumber;
      this.goToTimestamp(this.currentReplayTime);
      this.update();
      players = [this.player, this.opponent];
      playerIndex = 0;
      if (this.turns.length === 0) {
        turnNumber = 1;
        actionIndex = 0;
        currentPlayer = players[playerIndex];
        console.log('currentPlayer', currentPlayer, players[0]);
        ref = this.history;
        for (i = k = 0, len = ref.length; k < len; i = ++k) {
          batch = ref[i];
          ref1 = batch.commands;
          for (j = l = 0, len1 = ref1.length; l < len1; j = ++l) {
            command = ref1[j];
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 2 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
              this.turns[turnNumber] = {
                historyPosition: i,
                turn: 'mulligan',
                timestamp: batch.timestamp || 0,
                actions: [],
                activePlayer: currentPlayer
              };
              this.turns.length++;
              turnNumber++;
              actionIndex = 0;
              currentPlayer = players[++playerIndex % 2];
              console.log('batch', i, batch);
              console.log('\tProcessed mulligan, current player is now', currentPlayer);
            }
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 3 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
              currentPlayer = players[++playerIndex % 2];
              console.log('batch', i, batch);
              console.log('\tProcessed mulligan, current player is now', currentPlayer);
            }
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 1 && command[1][0].tag === 'STEP' && command[1][0].value === 6) {
              this.turns[turnNumber] = {
                historyPosition: i,
                turn: turnNumber,
                timestamp: batch.timestamp,
                actions: [],
                activePlayer: currentPlayer
              };
              this.turns.length++;
              turnNumber++;
              actionIndex = 0;
              currentPlayer = players[++playerIndex % 2];
              console.log('batch', i, batch);
              console.log('\tProcessed end of turn, current player is now', currentPlayer);
            }
            if (command[0] === 'receiveAction') {
              currentTurnNumber = turnNumber - 1;
              if (this.turns[currentTurnNumber]) {
                if (command[1].length > 0 && command[1][0].tags) {
                  playedCard = -1;
                  console.log('considering action', currentTurnNumber, command[1][0].tags, command);
                  ref2 = command[1][0].tags;
                  for (m = 0, len2 = ref2.length; m < len2; m++) {
                    tag = ref2[m];
                    if (tag.tag === 'ZONE' && tag.value === 1) {
                      playedCard = tag.entity;
                    }
                  }
                  if (playedCard > -1) {
                    console.log('batch', i, batch);
                    console.log('\tcommand', j, command);
                    action = {
                      turn: currentTurnNumber,
                      index: actionIndex++,
                      timestamp: batch.timestamp,
                      type: ': ',
                      data: this.entities[playedCard],
                      owner: this.turns[currentTurnNumber].activePlayer
                    };
                    this.turns[currentTurnNumber].actions[actionIndex] = action;
                    console.log('\t\tadding action to turn', this.turns[currentTurnNumber].actions[actionIndex]);
                  }
                }
                if (command[1].length > 0 && parseInt(command[1][0].attributes.target) > 0) {
                  console.log('considering attack', command[1][0]);
                  action = {
                    turn: currentTurnNumber,
                    index: actionIndex++,
                    timestamp: batch.timestamp,
                    type: ': ',
                    data: this.entities[command[1][0].attributes.entity],
                    owner: this.turns[currentTurnNumber].activePlayer,
                    target: this.entities[command[1][0].attributes.target]
                  };
                  this.turns[currentTurnNumber].actions[actionIndex] = action;
                  console.log('\t\tadding attack to turn', this.turns[currentTurnNumber].actions[actionIndex]);
                }
                if (command[1].length > 0 && command[1][0].showEntity) {
                  console.log('considering action for entity ' + command[1][0].showEntity.id, command[1][0].showEntity.tags, command[1][0]);
                  playedCard = -1;
                  ref3 = command[1][0].showEntity.tags;
                  for (entityTag in ref3) {
                    tagValue = ref3[entityTag];
                    console.log('\t\tLooking at ', entityTag, tagValue);
                    if (entityTag === 'ZONE' && tagValue === 1) {
                      playedCard = command[1][0].showEntity.id;
                    }
                  }
                  ref4 = command[1][0].tags;
                  for (n = 0, len3 = ref4.length; n < len3; n++) {
                    tag = ref4[n];
                    console.log('\ttag', tag.tag, tag.value, tag);
                    if (tag.tag === 'ZONE' && tag.value === 1) {
                      playedCard = tag.entity;
                    }
                  }
                  if (playedCard > -1) {
                    action = {
                      turn: currentTurnNumber,
                      index: actionIndex++,
                      timestamp: batch.timestamp,
                      type: ': ',
                      data: this.entities[command[1][0].showEntity.id] ? this.entities[command[1][0].showEntity.id] : command[1][0].showEntity,
                      owner: this.turns[currentTurnNumber].activePlayer,
                      debug: command[1][0].showEntity
                    };
                    if (action.data) {
                      console.log('batch', i, batch);
                      console.log('\tcommand', j, command);
                      console.log('\t\tadding showEntity', command[1][0].showEntity, action);
                      this.turns[currentTurnNumber].actions[actionIndex] = action;
                    }
                  }
                }
              }
            }
            if (command[0] === 'receiveShowEntity') {
              if (command[1].length > 0 && command[1][0].id && this.entities[command[1][0].id]) {
                this.entities[command[1][0].id].cardID = command[1][0].cardID;
              }
            }
          }
        }
        console.log(this.turns.length, 'game turns at position', this.turns);
      }
      console.log('finalizing init, player are', this.player, this.opponent, this.players);
      if (parseInt(this.opponent.id) === parseInt(this.mainPlayerId)) {
        tempOpponent = this.player;
        this.player = this.opponent;
        this.opponent = tempOpponent;
      }
      return this.emit('players-ready');
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

    ReplayPlayer.prototype.receiveAction = function(definition) {};

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

    return ReplayPlayer;

  })(EventEmitter);

  module.exports = ReplayPlayer;

}).call(this);
