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
      this.currentTurn = 0;
      this.currentActionInTurn = 0;
      this.turnLog = '';
      this.cardUtils = window['parseCardsText'];
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
      this.frequency = 2000;
      this.currentReplayTime = 200;
      this.started = false;
      this.speed = 0;
      this.turns = {
        length: 0
      };
      this.parser.parse(this);
      this.finalizeInit();
      this.goNextAction();
      return console.log('replay init done', this.turns);
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
      this.previousSpeed = this.speed;
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

    ReplayPlayer.prototype.goNextAction = function() {
      this.newStep();
      this.turnLog = '';
      this.currentActionInTurn++;
      if (this.turns[this.currentTurn] && this.currentActionInTurn <= this.turns[this.currentTurn].actions.length - 1) {
        return this.goToAction();
      } else {
        return this.goNextTurn();
      }
    };

    ReplayPlayer.prototype.goPreviousAction = function() {
      this.newStep();
      this.turnLog = '';
      console.log('going to previous action', this.currentActionInTurn, this.currentActionInTurn - 1, this.currentTurn);
      this.currentActionInTurn--;
      if (this.currentActionInTurn === 1) {
        console.log('going directly to beginning of turn', this.currentTurn);
        this.goPreviousTurn();
        return this.goNextTurn();
      } else if (this.currentActionInTurn <= 0) {
        console.log('going directly to end of previous turn', this.currentTurn - 1);
        this.goPreviousTurn();
        console.log('moved back to previous turn', this.currentTurn);
        this.currentActionInTurn = this.turns[this.currentTurn].actions.length - 1;
        if (this.currentActionInTurn > 0) {
          return this.goToAction();
        }
      } else if (this.turns[this.currentTurn]) {
        return this.goToAction();
      }
    };

    ReplayPlayer.prototype.goToAction = function() {
      var action, card, cardLink, owner, ownerCard, ref, target, targetTimestamp;
      this.newStep();
      console.log('currentTurn', this.currentTurn, this.turns[this.currentTurn]);
      console.log('currentActionInTurn', this.currentActionInTurn, this.turns[this.currentTurn].actions);
      if (this.currentActionInTurn >= 0) {
        action = this.turns[this.currentTurn].actions[this.currentActionInTurn];
        console.log('action', this.currentActionInTurn, this.turns[this.currentTurn], this.turns[this.currentTurn].actions[this.currentActionInTurn]);
        targetTimestamp = 1000 * (action.timestamp - this.startTimestamp) + 1;
        console.log('executing action', action, action.data, this.startTimestamp);
        card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
        owner = action.owner.name;
        if (!owner) {
          ownerCard = this.entities[action.owner];
          owner = this.cardUtils.buildCardLink(this.cardUtils.getCard(ownerCard.cardID));
        }
        console.log('building card link for', card, this.cardUtils.getCard(card));
        cardLink = action.secret ? 'Secret' : this.cardUtils.buildCardLink(this.cardUtils.getCard(card));
        this.turnLog = owner + action.type + cardLink;
        if (action.target) {
          target = this.entities[action.target];
          this.targetSource = action != null ? action.data.id : void 0;
          this.targetDestination = target.id;
          this.turnLog += ' -> ' + this.cardUtils.buildCardLink(this.cardUtils.getCard(target.cardID));
        }
      } else {
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
        this.turnLog = this.turns[this.currentTurn].turn + ((ref = this.turns[this.currentTurn].activePlayer) != null ? ref.name : void 0);
      }
      return this.goToTimestamp(targetTimestamp);
    };

    ReplayPlayer.prototype.goNextTurn = function() {
      var targetTimestamp;
      this.newStep();
      this.currentActionInTurn = 0;
      this.currentTurn++;
      if (this.turns[this.currentTurn].turn === 'Mulligan') {
        this.turnLog = this.turns[this.currentTurn].turn;
      } else if (this.turns[this.currentTurn].activePlayer === this.player) {
        this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + ': ' + this.turns[this.currentTurn].activePlayer.name;
      } else {
        this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + 'o: ' + this.turns[this.currentTurn].activePlayer.name;
      }
      targetTimestamp = this.getTotalLength() * 1000;
      if (this.currentTurn <= this.turns.length && this.turns[this.currentTurn].actions && this.turns[this.currentTurn].actions.length > 0) {
        this.currentActionInTurn = 1;
        targetTimestamp = 1000 * (this.turns[this.currentTurn].actions[this.currentActionInTurn].timestamp - this.startTimestamp) + 1;
      } else {
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
      }
      return this.goToTimestamp(targetTimestamp);
    };

    ReplayPlayer.prototype.goPreviousTurn = function() {
      var targetTimestamp;
      this.newStep();
      this.currentActionInTurn = 0;
      console.log('going to previous turn', this.currentTurn, this.currentTurn - 1, this.currentActionInTurn, this.turns);
      this.currentTurn = Math.max(this.currentTurn - 1, 1);
      if (this.currentTurn <= 1) {
        targetTimestamp = 200;
        this.currentTurn = 1;
      } else if (this.currentTurn <= this.turns.length && this.turns[this.currentTurn].actions && this.turns[this.currentTurn].actions.length > 0) {
        this.currentActionInTurn = 1;
        targetTimestamp = 1000 * (this.turns[this.currentTurn].actions[this.currentActionInTurn].timestamp - this.startTimestamp) + 1;
      } else {
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
      }
      if (this.turns[this.currentTurn].turn === 'Mulligan') {
        console.log('in Mulligan', this.turns[this.currentTurn], this.currentTurn, targetTimestamp);
        this.turnLog = this.turns[this.currentTurn].turn;
        this.currentTurn = 0;
        this.currentActionInTurn = 0;
      } else {
        this.turnLog = 't' + this.turns[this.currentTurn].turn + ': ' + this.turns[this.currentTurn].activePlayer.name;
      }
      this.goToTimestamp(targetTimestamp);
      return console.log('at previous turn', this.currentTurn, this.currentActionInTurn, this.turnLog);
    };

    ReplayPlayer.prototype.newStep = function() {
      this.targetSource = void 0;
      return this.targetDestination = void 0;
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
      return this.moveToTimestamp(target);
    };

    ReplayPlayer.prototype.moveToTimestamp = function(timestamp) {
      var action, i, j, k, l, ref, ref1, ref2, turn;
      console.log('moving to timestamp', timestamp, this.startTimestamp, timestamp + this.startTimestamp);
      timestamp += this.startTimestamp;
      this.newStep();
      this.currentTurn = -1;
      this.currentActionInTurn = -1;
      for (i = k = 1, ref = this.turns.length; 1 <= ref ? k <= ref : k >= ref; i = 1 <= ref ? ++k : --k) {
        turn = this.turns[i];
        if (((ref1 = turn.actions) != null ? ref1.length : void 0) > 0 && turn.actions[1].timestamp > timestamp) {
          break;
        }
        this.currentTurn = i;
        if (turn.actions.length > 0) {
          for (j = l = 1, ref2 = turn.actions.length - 1; 1 <= ref2 ? l <= ref2 : l >= ref2; j = 1 <= ref2 ? ++l : --l) {
            action = turn.actions[j];
            if (!action || !action.timestamp || (action != null ? action.timestamp : void 0) > timestamp) {
              break;
            }
            this.currentActionInTurn = j;
          }
        }
      }
      if (this.currentActionInTurn <= 1) {
        console.log('Going to turn', timestamp, this.currentTurn, this.currentActionInTurn, this.turns[this.currentTurn].actions[this.currentActionInTurn]);
        if (this.currentTurn <= 1) {
          return this.goPreviousTurn();
        } else {
          this.currentTurn = Math.max(this.currentTurn - 1, 1);
          this.goToAction();
          return this.goNextTurn();
        }
      } else {
        console.log('Going to action', timestamp, this.currentTurn, this.currentActionInTurn, this.turns[this.currentTurn].actions[this.currentActionInTurn]);
        return this.goToAction();
      }
    };

    ReplayPlayer.prototype.goToTimestamp = function(timestamp) {
      console.log('going to timestamp', timestamp);
      if (timestamp < this.currentReplayTime) {
        this.historyPosition = 0;
        this.init();
      }
      this.currentReplayTime = timestamp;
      this.update();
      return this.emit('moved-timestamp');
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
          console.log('\tmatch', match);
          inputTurnNumber = parseInt(match.substring(1, match.length - 1));
          console.log('\tinputTurnNumber', inputTurnNumber);
          if (that.turns[2].activePlayer === that.player) {
            turnNumber = inputTurnNumber * 2;
          } else {
            turnNumber = inputTurnNumber * 2 + 1;
          }
          turn = that.turns[turnNumber];
          console.log('\tturn', turn);
          if (turn) {
            timestamp = turn.timestamp + 1;
            console.log('\ttimestamp', timestamp - that.startTimestamp);
            formattedTimeStamp = that.formatTimeStamp(timestamp - that.startTimestamp);
            console.log('\tformattedTimeStamp', formattedTimeStamp);
            return text = text.replace(match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>');
          }
        });
      }
      matches = text.match(opoonentTurnRegex);
      if (matches && matches.length > 0) {
        matches.forEach(function(match) {
          var formattedTimeStamp, inputTurnNumber, timestamp, turn, turnNumber;
          console.log('\tmatch', match);
          inputTurnNumber = parseInt(match.substring(1, match.length - 1));
          console.log('\tinputTurnNumber', inputTurnNumber);
          if (that.turns[2].activePlayer === that.opponent) {
            turnNumber = inputTurnNumber * 2;
          } else {
            turnNumber = inputTurnNumber * 2 + 1;
          }
          turn = that.turns[turnNumber];
          console.log('\tturn', turn);
          if (turn) {
            timestamp = turn.timestamp + 1;
            console.log('\ttimestamp', timestamp - that.startTimestamp);
            formattedTimeStamp = that.formatTimeStamp(timestamp - that.startTimestamp);
            console.log('\tformattedTimeStamp', formattedTimeStamp);
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
          console.log('timestamp', timestamp, that.startTimestamp);
          formattedTimeStamp = that.formatTimeStamp(timestamp - that.startTimestamp);
          console.log('formatted time stamp', formattedTimeStamp);
          return text = text.replace(match, '<a ng-click="goToTimestamp(\'' + formattedTimeStamp + '\')" class="ng-scope">' + match + '</a>');
        });
      }
      console.log('modified text', text);
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

    ReplayPlayer.prototype.finalizeInit = function() {
      var action, actionIndex, batch, command, currentPlayer, currentTurnNumber, dmg, entityTag, i, j, k, l, len, len1, len2, len3, len4, len5, m, n, o, p, playedCard, playerIndex, players, ref, ref1, ref2, ref3, ref4, ref5, ref6, secret, tag, tagValue, target, tempOpponent, turnNumber;
      this.goToTimestamp(this.currentReplayTime);
      this.update();
      players = [this.player, this.opponent];
      playerIndex = 0;
      if (this.turns.length === 0) {
        turnNumber = 1;
        actionIndex = 0;
        currentPlayer = players[playerIndex];
        ref = this.history;
        for (i = k = 0, len = ref.length; k < len; i = ++k) {
          batch = ref[i];
          ref1 = batch.commands;
          for (j = l = 0, len1 = ref1.length; l < len1; j = ++l) {
            command = ref1[j];
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 2 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
              this.turns[turnNumber] = {
                historyPosition: i,
                turn: 'Mulligan',
                timestamp: batch.timestamp,
                actions: []
              };
              this.turns.length++;
              turnNumber++;
              actionIndex = 0;
              currentPlayer = players[++playerIndex % 2];
            }
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 3 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
              currentPlayer = players[++playerIndex % 2];
            }
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 1 && command[1][0].tag === 'STEP' && command[1][0].value === 6) {
              this.turns[turnNumber] = {
                historyPosition: i,
                turn: turnNumber - 1,
                timestamp: batch.timestamp,
                actions: [],
                activePlayer: currentPlayer
              };
              this.turns.length++;
              turnNumber++;
              actionIndex = 0;
              currentPlayer = players[++playerIndex % 2];
            }
            if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].tag === 'NUM_CARDS_DRAWN_THIS_TURN' && command[1][0].value > 0) {
              if (this.turns[currentTurnNumber]) {
                action = {
                  turn: currentTurnNumber,
                  index: actionIndex++,
                  timestamp: batch.timestamp,
                  type: ' draw: ',
                  data: this.entities[playedCard],
                  owner: this.entities[command[1][0].entity],
                  initialCommand: command[1][0]
                };
                this.turns[currentTurnNumber].actions[actionIndex] = action;
              }
            }
            if (command[0] === 'receiveAction') {
              currentTurnNumber = turnNumber - 1;
              if (this.turns[currentTurnNumber]) {
                if (command[1].length > 0 && command[1][0].tags) {
                  playedCard = -1;
                  ref2 = command[1][0].tags;
                  for (m = 0, len2 = ref2.length; m < len2; m++) {
                    tag = ref2[m];
                    if (tag.tag === 'ZONE' && tag.value === 1) {
                      playedCard = tag.entity;
                    }
                    if (tag.tag === 'SECRET' && tag.value === 1) {
                      secret = true;
                    }
                  }
                  if (playedCard > -1) {
                    action = {
                      turn: currentTurnNumber - 1,
                      index: actionIndex++,
                      timestamp: batch.timestamp,
                      type: ': ',
                      secret: secret,
                      data: this.entities[playedCard],
                      owner: this.turns[currentTurnNumber].activePlayer,
                      initialCommand: command[1][0]
                    };
                    this.turns[currentTurnNumber].actions[actionIndex] = action;
                  }
                }
                if (command[1].length > 0 && command[1][0].tags && command[1][0].attributes.type === '6') {
                  ref3 = command[1][0].tags;
                  for (n = 0, len3 = ref3.length; n < len3; n++) {
                    tag = ref3[n];
                    if (tag.tag === 'ZONE' && tag.value === 4) {
                      action = {
                        turn: currentTurnNumber - 1,
                        index: actionIndex++,
                        timestamp: batch.timestamp,
                        type: ' died ',
                        owner: tag.entity,
                        initialCommand: command[1][0]
                      };
                      this.turns[currentTurnNumber].actions[actionIndex] = action;
                    }
                  }
                }
                if (command[1].length > 0 && parseInt(command[1][0].attributes.target) > 0 && (command[1][0].attributes.type === '1' || !command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)) {
                  action = {
                    turn: currentTurnNumber - 1,
                    index: actionIndex++,
                    timestamp: batch.timestamp,
                    type: ': ',
                    data: this.entities[command[1][0].attributes.entity],
                    owner: this.turns[currentTurnNumber].activePlayer,
                    target: command[1][0].attributes.target,
                    initialCommand: command[1][0]
                  };
                  this.turns[currentTurnNumber].actions[actionIndex] = action;
                }
                if (command[1].length > 0 && command[1][0].attributes.type === '3') {
                  if (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0) {
                    if (command[1][0].tags) {
                      dmg = 0;
                      target = void 0;
                      ref4 = command[1][0].tags;
                      for (o = 0, len4 = ref4.length; o < len4; o++) {
                        tag = ref4[o];
                        if (tag.tag === 'DAMAGE' && tag.value > 0) {
                          dmg = tag.value;
                          target = tag.entity;
                        }
                      }
                      if (dmg > 0) {
                        action = {
                          turn: currentTurnNumber - 1,
                          index: actionIndex++,
                          timestamp: batch.timestamp,
                          prefix: '\t',
                          type: ': ',
                          data: this.entities[command[1][0].attributes.entity],
                          owner: this.turns[currentTurnNumber].activePlayer,
                          target: target,
                          initialCommand: command[1][0]
                        };
                        this.turns[currentTurnNumber].actions[actionIndex] = action;
                      }
                    }
                    if (command[1][0].fullEntity) {
                      action = {
                        turn: currentTurnNumber - 1,
                        index: actionIndex++,
                        timestamp: batch.timestamp,
                        prefix: '\t',
                        type: ': ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.turns[currentTurnNumber].activePlayer,
                        target: target,
                        initialCommand: command[1][0]
                      };
                      this.turns[currentTurnNumber].actions[actionIndex] = action;
                    }
                  }
                }
                if (command[1].length > 0 && command[1][0].showEntity && (command[1][0].attributes.type === '1' || (command[1][0].attributes.type !== '3' && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)))) {
                  playedCard = -1;
                  if (command[1][0].showEntity.tags) {
                    ref5 = command[1][0].showEntity.tags;
                    for (entityTag in ref5) {
                      tagValue = ref5[entityTag];
                      if (entityTag === 'ZONE' && tagValue === 1) {
                        playedCard = command[1][0].showEntity.id;
                      }
                    }
                  }
                  if (command[1][0].tags) {
                    ref6 = command[1][0].tags;
                    for (p = 0, len5 = ref6.length; p < len5; p++) {
                      tag = ref6[p];
                      if (tag.tag === 'ZONE' && tag.value === 1) {
                        playedCard = tag.entity;
                      }
                    }
                  }
                  if (playedCard > -1) {
                    action = {
                      turn: currentTurnNumber - 1,
                      index: actionIndex++,
                      timestamp: batch.timestamp,
                      type: ': ',
                      data: this.entities[command[1][0].showEntity.id] ? this.entities[command[1][0].showEntity.id] : command[1][0].showEntity,
                      owner: this.turns[currentTurnNumber].activePlayer,
                      debugType: 'showEntity',
                      debug: command[1][0].showEntity,
                      initialCommand: command[1][0]
                    };
                    if (action.data) {
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
      }
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
