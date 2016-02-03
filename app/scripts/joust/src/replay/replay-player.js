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
      console.log('starting init');
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
      this.buildCardLink = this.cardUtils.buildCardLink;
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

    ReplayPlayer.prototype.buildGameLog = function() {
      var fullLog, indent, initialAction, initialTurn, k, ref;
      console.log('building full game log');
      fullLog = '';
      initialTurn = this.currentTurn;
      initialAction = this.currentActionInTurn;
      this.currentTurn = 1;
      this.currentActionInTurn = 0;
      while (this.turns[this.currentTurn]) {
        this.newStep();
        this.turnLog = '';
        this.currentActionInTurn++;
        if (this.turns[this.currentTurn] && this.currentActionInTurn <= this.turns[this.currentTurn].actions.length - 1) {
          this.buildActionLog();
          fullLog += '\t';
          console.log(this.turnLog);
          console.log('\tinitial action', this.turns[this.currentTurn].actions[this.currentActionInTurn]);
          if (this.turns[this.currentTurn].actions[this.currentActionInTurn].initialCommand.indent) {
            for (indent = k = 0, ref = this.turns[this.currentTurn].actions[this.currentActionInTurn].initialCommand.indent - 1; 0 <= ref ? k <= ref : k >= ref; indent = 0 <= ref ? ++k : --k) {
              fullLog += '\t';
            }
          }
        } else {
          this.currentActionInTurn = 0;
          this.currentTurn++;
          if (this.turns[this.currentTurn]) {
            if (this.turns[this.currentTurn].turn === 'Mulligan') {
              this.turnLog = this.turns[this.currentTurn].turn;
            } else if (this.turns[this.currentTurn].activePlayer === this.player) {
              this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + ': ' + this.turns[this.currentTurn].activePlayer.name;
            } else {
              this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + 'o: ' + this.turns[this.currentTurn].activePlayer.name;
            }
          }
        }
        fullLog += this.turnLog + '\n';
      }
      this.buildCardLink = this.cardUtils.buildCardLink;
      this.currentTurn = initialTurn;
      this.currentActionInTurn = initialAction;
      console.log('game log');
      return console.info('experimental: full game log\n', fullLog);
    };

    ReplayPlayer.prototype.buildLogCardLink = function(card) {
      if (card) {
        return card.name;
      } else {
        return '';
      }
    };

    ReplayPlayer.prototype.goNextAction = function() {
      console.log('clicked goNextAction', this.currentTurn, this.currentActionInTurn);
      this.newStep();
      this.turnLog = '';
      this.currentActionInTurn++;
      console.log('goNextAction', this.turns[this.currentTurn], this.currentActionInTurn, this.turns[this.currentTurn] ? this.turns[this.currentTurn].actions : void 0);
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
          console.log('moving to action', this.currentActionInTurn);
          return this.goToAction();
        }
      } else if (this.turns[this.currentTurn]) {
        return this.goToAction();
      }
    };

    ReplayPlayer.prototype.goToAction = function() {
      var targetTimestamp;
      this.newStep();
      console.log('currentTurn', this.currentTurn, this.turns[this.currentTurn]);
      console.log('currentActionInTurn', this.currentActionInTurn, this.turns[this.currentTurn].actions);
      targetTimestamp = this.buildActionLog();
      console.log(this.turnLog);
      return this.goToTimestamp(targetTimestamp);
    };

    ReplayPlayer.prototype.buildActionLog = function() {
      var action, card, cardLink, creator, owner, ownerCard, ref, target, targetTimestamp;
      if (this.currentActionInTurn >= 0) {
        action = this.turns[this.currentTurn].actions[this.currentActionInTurn];
        targetTimestamp = 1000 * (action.timestamp - this.startTimestamp) + 1;
        card = (action != null ? action.data : void 0) ? action.data['cardID'] : '';
        owner = action.owner.name;
        if (!owner) {
          ownerCard = this.entities[action.owner];
          owner = this.buildCardLink(this.cardUtils.getCard(ownerCard.cardID));
        }
        cardLink = this.buildCardLink(this.cardUtils.getCard(card));
        if (action.secret) {
          if ((cardLink != null ? cardLink.length : void 0) > 0 && action.publicSecret) {
            cardLink += ' -> Secret';
          } else {
            cardLink = 'Secret';
          }
        }
        creator = '';
        if (action.creator) {
          creator = this.buildCardLink(this.cardUtils.getCard(action.creator.cardID)) + ': ';
        }
        this.turnLog = owner + action.type + creator + cardLink;
        if (action.target) {
          target = this.entities[action.target];
          this.targetSource = action != null ? action.data.id : void 0;
          this.targetDestination = target.id;
          this.targetType = action.actionType;
          this.turnLog += ' -> ' + this.buildCardLink(this.cardUtils.getCard(target.cardID));
        }
      } else {
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
        this.turnLog = this.turns[this.currentTurn].turn + ((ref = this.turns[this.currentTurn].activePlayer) != null ? ref.name : void 0);
      }
      return targetTimestamp;
    };

    ReplayPlayer.prototype.goNextTurn = function() {
      var targetTimestamp;
      this.newStep();
      this.currentActionInTurn = 0;
      this.currentTurn++;
      if (!this.turns[this.currentTurn]) {
        return;
      }
      if (this.turns[this.currentTurn].turn === 'Mulligan') {
        this.turnLog = this.turns[this.currentTurn].turn;
      } else if (this.turns[this.currentTurn].activePlayer === this.player) {
        this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + ': ' + this.turns[this.currentTurn].activePlayer.name;
      } else {
        this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + 'o: ' + this.turns[this.currentTurn].activePlayer.name;
      }
      targetTimestamp = this.getTotalLength() * 1000;
      targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
      return this.goToTimestamp(targetTimestamp);
    };

    ReplayPlayer.prototype.goPreviousTurn = function() {
      var targetTimestamp;
      this.newStep();
      this.currentActionInTurn = 0;
      console.log('going to previous turn', this.currentTurn, this.currentTurn - 1, this.turns);
      this.currentTurn = Math.max(this.currentTurn - 1, 1);
      if (this.currentTurn <= 1) {
        targetTimestamp = 200;
        this.currentTurn = 1;
      } else if (this.currentTurn <= this.turns.length && this.turns[this.currentTurn].actions && this.turns[this.currentTurn].actions.length > 1) {
        this.currentActionInTurn = 1;
        console.log('\tGoing to action', this.turns[this.currentTurn].actions[this.currentActionInTurn]);
        targetTimestamp = 1000 * (this.turns[this.currentTurn].actions[this.currentActionInTurn].timestamp - this.startTimestamp) + 1;
      } else {
        console.log('\tGoing to turn', this.turns[this.currentTurn]);
        targetTimestamp = 1000 * (this.turns[this.currentTurn].timestamp - this.startTimestamp) + 1;
      }
      if (this.turns[this.currentTurn].turn === 'Mulligan') {
        console.log('in Mulligan', this.turns[this.currentTurn], this.currentTurn, targetTimestamp);
        this.turnLog = this.turns[this.currentTurn].turn;
        this.currentTurn = 0;
        this.currentActionInTurn = 0;
        this.goToTimestamp(targetTimestamp);
      } else {
        this.goToTimestamp(targetTimestamp);
        if (this.turns[this.currentTurn].activePlayer === this.player) {
          this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + ': ' + this.turns[this.currentTurn].activePlayer.name;
        } else {
          this.turnLog = 't' + Math.ceil(this.turns[this.currentTurn].turn / 2) + 'o: ' + this.turns[this.currentTurn].activePlayer.name;
        }
      }
      return console.log('at previous turn', this.currentTurn, this.currentActionInTurn, this.turnLog);
    };

    ReplayPlayer.prototype.getActivePlayer = function() {
      return this.turns[this.currentTurn].activePlayer || {};
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
      target = this.getTotalLength() * progression;
      return this.moveToTimestamp(target);
    };

    ReplayPlayer.prototype.moveToTimestamp = function(timestamp) {
      var action, i, j, k, l, ref, ref1, ref2, ref3, turn;
      timestamp += this.startTimestamp;
      this.newStep();
      this.currentTurn = -1;
      this.currentActionInTurn = -1;
      for (i = k = 1, ref = this.turns.length; 1 <= ref ? k <= ref : k >= ref; i = 1 <= ref ? ++k : --k) {
        turn = this.turns[i];
        if ((((ref1 = turn.actions) != null ? ref1.length : void 0) > 0 && turn.actions[1].timestamp > timestamp) || (((ref2 = turn.actions) != null ? ref2.length : void 0) === 0 && turn.timestamp > timestamp)) {
          break;
        }
        this.currentTurn = i;
        if (turn.actions.length > 0) {
          for (j = l = 1, ref3 = turn.actions.length - 1; 1 <= ref3 ? l <= ref3 : l >= ref3; j = 1 <= ref3 ? ++l : --l) {
            action = turn.actions[j];
            if (!action || !action.timestamp || (action != null ? action.timestamp : void 0) > timestamp) {
              break;
            }
            this.currentActionInTurn = j;
          }
        }
      }
      if (this.currentTurn === -1) {
        this.currentTurn = 0;
        this.currentActionInTurn = 0;
        this.historyPosition = 0;
        return this.init();
      } else if (this.currentTurn === 1) {
        this.currentTurn = 0;
        this.currentActionInTurn = 0;
        this.historyPosition = 0;
        this.init();
        return this.goNextTurn();
      } else if (this.currentActionInTurn <= 1) {
        this.currentTurn = Math.max(this.currentTurn - 1, 1);
        this.goToAction();
        return this.goNextTurn();
      } else {
        return this.goToAction();
      }
    };

    ReplayPlayer.prototype.goToTimestamp = function(timestamp) {
      console.log('going to timestamp', timestamp);
      if (timestamp < this.currentReplayTime) {
        console.log('going back in time, resetting', timestamp, this.currentReplayTime);
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

    ReplayPlayer.prototype.finalizeInit = function() {
      var action, actionIndex, armor, batch, command, currentPlayer, currentTurnNumber, definition, dmg, entity, entityTag, excluded, i, info, j, k, l, len, len1, len10, len11, len12, len2, len3, len4, len5, len6, len7, len8, len9, m, meta, n, o, p, playedCard, playerIndex, players, publicSecret, q, r, ref, ref1, ref10, ref11, ref12, ref13, ref14, ref15, ref16, ref17, ref18, ref19, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, s, secret, t, tag, tagValue, target, turnNumber, u, v, w;
      this.goToTimestamp(this.currentReplayTime);
      this.update();
      players = [this.player, this.opponent];
      playerIndex = 0;
      turnNumber = 1;
      actionIndex = 0;
      currentPlayer = players[playerIndex];
      ref = this.history;
      for (i = k = 0, len = ref.length; k < len; i = ++k) {
        batch = ref[i];
        ref1 = batch.commands;
        for (j = l = 0, len1 = ref1.length; l < len1; j = ++l) {
          command = ref1[j];
          if (command[0] === 'receiveShowEntity') {
            if (command[1].length > 0 && command[1][0].id && this.entities[command[1][0].id]) {
              this.entities[command[1][0].id].cardID = command[1][0].cardID;
            }
          }
          if (command[0] === 'receiveEntity') {
            if (command[1].length > 0 && command[1][0].id && !this.entities[command[1][0].id]) {
              entity = new Entity(this);
              definition = _.cloneDeep(command[1][0]);
              this.entities[definition.id] = entity;
              definition.tags.ZONE = 6;
              entity.update(definition);
            }
          }
        }
      }
      playerIndex = 0;
      turnNumber = 1;
      actionIndex = 0;
      currentPlayer = players[playerIndex];
      ref2 = this.history;
      for (i = m = 0, len2 = ref2.length; m < len2; i = ++m) {
        batch = ref2[i];
        ref3 = batch.commands;
        for (j = n = 0, len3 = ref3.length; n < len3; j = ++n) {
          command = ref3[j];
          if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 2 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
            this.turns[turnNumber] = {
              historyPosition: i,
              turn: 'Mulligan',
              playerMulligan: [],
              opponentMulligan: [],
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
              command[1][0].indent = command[1][0].indent > 1 ? command[1][0].indent - 1 : void 0;
              action = {
                turn: currentTurnNumber,
                index: actionIndex++,
                timestamp: batch.timestamp,
                type: ': draw ',
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
              if (command[1][0].attributes.type === '5' && currentTurnNumber === 1 && command[1][0].hideEntities) {
                if (command[1][0].attributes.entity === this.mainPlayerId) {
                  this.turns[currentTurnNumber].playerMulligan = command[1][0].hideEntities;
                } else {
                  this.turns[currentTurnNumber].opponentMulligan = command[1][0].hideEntities;
                }
              }
              if (command[1][0].tags && command[1][0].attributes.type !== '5') {
                playedCard = -1;
                excluded = false;
                secret = false;
                ref4 = command[1][0].tags;
                for (o = 0, len4 = ref4.length; o < len4; o++) {
                  tag = ref4[o];
                  if (tag.tag === 'ZONE' && ((ref5 = tag.value) === 1 || ref5 === 7)) {
                    playedCard = tag.entity;
                  }
                  if (tag.tag === 'SECRET' && tag.value === 1) {
                    secret = true;
                    publicSecret = command[1][0].attributes.type === '7' && this.turns[currentTurnNumber].activePlayer.id === this.mainPlayerId;
                  }
                  if (tag.tag === 'ATTACHED') {
                    excluded = true;
                  }
                }
                if (playedCard > -1 && !excluded) {
                  action = {
                    turn: currentTurnNumber - 1,
                    index: actionIndex++,
                    timestamp: batch.timestamp,
                    type: ': ',
                    secret: secret,
                    publicSecret: publicSecret,
                    data: this.entities[playedCard],
                    owner: this.turns[currentTurnNumber].activePlayer,
                    initialCommand: command[1][0],
                    debugType: 'played card'
                  };
                  this.turns[currentTurnNumber].actions[actionIndex] = action;
                }
              }
              if (command[1].length > 0 && command[1][0].showEntity && (command[1][0].attributes.type === '1' || (command[1][0].attributes.type !== '3' && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)))) {
                playedCard = -1;
                if (command[1][0].showEntity.tags) {
                  ref6 = command[1][0].showEntity.tags;
                  for (entityTag in ref6) {
                    tagValue = ref6[entityTag];
                    if (entityTag === 'ZONE' && tagValue === 1) {
                      playedCard = command[1][0].showEntity.id;
                    }
                  }
                }
                if (command[1][0].tags) {
                  ref7 = command[1][0].tags;
                  for (p = 0, len5 = ref7.length; p < len5; p++) {
                    tag = ref7[p];
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
              if (command[1][0].tags && command[1][0].attributes.type === '5') {
                playedCard = -1;
                excluded = false;
                secret = false;
                ref8 = command[1][0].tags;
                for (q = 0, len6 = ref8.length; q < len6; q++) {
                  tag = ref8[q];
                  if (tag.tag === 'ZONE' && ((ref9 = tag.value) === 1 || ref9 === 7)) {
                    playedCard = tag.entity;
                  }
                  if (tag.tag === 'SECRET' && tag.value === 1) {
                    secret = true;
                  }
                  if (tag.tag === 'ATTACHED') {
                    excluded = true;
                  }
                }
                if (playedCard > -1 && !excluded) {
                  action = {
                    turn: currentTurnNumber - 1,
                    index: actionIndex++,
                    timestamp: batch.timestamp,
                    type: ': ',
                    secret: secret,
                    data: this.entities[playedCard],
                    owner: command[1][0].attributes.entity,
                    initialCommand: command[1][0],
                    debugType: 'played card from tigger'
                  };
                  this.turns[currentTurnNumber].actions[actionIndex] = action;
                }
              }
              if (command[1][0].tags && ((ref10 = command[1][0].attributes.type) === '3' || ref10 === '5') && ((ref11 = command[1][0].meta) != null ? ref11.length : void 0) > 0) {
                ref12 = command[1][0].meta;
                for (r = 0, len7 = ref12.length; r < len7; r++) {
                  meta = ref12[r];
                  ref13 = meta.info;
                  for (s = 0, len8 = ref13.length; s < len8; s++) {
                    info = ref13[s];
                    if (meta.meta === 'TARGET' && ((ref14 = meta.info) != null ? ref14.length : void 0) > 0 && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) !== info.entity)) {
                      action = {
                        turn: currentTurnNumber - 1,
                        index: actionIndex++,
                        timestamp: batch.timestamp,
                        target: info.entity,
                        type: ': trigger ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.getController(this.entities[command[1][0].attributes.entity].tags.CONTROLLER),
                        initialCommand: command[1][0],
                        debugType: 'trigger effect card'
                      };
                      this.turns[currentTurnNumber].actions[actionIndex] = action;
                    }
                  }
                }
              }
              if (command[1][0].tags && command[1][0].attributes.type === '6') {
                ref15 = command[1][0].tags;
                for (t = 0, len9 = ref15.length; t < len9; t++) {
                  tag = ref15[t];
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
              if (parseInt(command[1][0].attributes.target) > 0 && (command[1][0].attributes.type === '1' || !command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)) {
                action = {
                  turn: currentTurnNumber - 1,
                  index: actionIndex++,
                  timestamp: batch.timestamp,
                  type: ': ',
                  actionType: 'attack',
                  data: this.entities[command[1][0].attributes.entity],
                  owner: this.turns[currentTurnNumber].activePlayer,
                  target: command[1][0].attributes.target,
                  initialCommand: command[1][0],
                  debugType: 'attack with complex conditions'
                };
                this.turns[currentTurnNumber].actions[actionIndex] = action;
              }
              if ((ref16 = command[1][0].attributes.type) === '3' || ref16 === '5') {
                if (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0) {
                  if (command[1][0].tags) {
                    dmg = 0;
                    target = void 0;
                    ref17 = command[1][0].tags;
                    for (u = 0, len10 = ref17.length; u < len10; u++) {
                      tag = ref17[u];
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
                        initialCommand: command[1][0],
                        debugType: 'power 3 dmg'
                      };
                      this.turns[currentTurnNumber].actions[actionIndex] = action;
                    }
                  }
                  if (command[1][0].fullEntity && command[1][0].fullEntity.tags.CARDTYPE !== 6) {
                    if (command[1][0].parent) {
                      ref18 = command[1][0].parent.tags;
                      for (v = 0, len11 = ref18.length; v < len11; v++) {
                        tag = ref18[v];
                        if (tag.tag === 'HEROPOWER_ACTIVATIONS_THIS_TURN' && tag.value > 0) {
                          command[1][0].indent = command[1][0].indent > 1 ? command[1][0].indent - 1 : void 0;
                          command[1][0].fullEntity.indent = command[1][0].fullEntity.indent > 1 ? command[1][0].fullEntity.indent - 1 : void 0;
                        }
                      }
                    }
                    action = {
                      turn: currentTurnNumber - 1,
                      index: actionIndex++,
                      timestamp: batch.timestamp,
                      prefix: '\t',
                      type: ': ',
                      data: this.entities[command[1][0].attributes.entity],
                      owner: this.turns[currentTurnNumber].activePlayer,
                      initialCommand: command[1][0],
                      debugType: 'power 3 root'
                    };
                    this.turns[currentTurnNumber].actions[actionIndex] = action;
                    action = {
                      turn: currentTurnNumber - 1,
                      index: actionIndex++,
                      timestamp: batch.timestamp,
                      prefix: '\t',
                      creator: this.entities[command[1][0].attributes.entity],
                      type: ': ',
                      data: this.entities[command[1][0].fullEntity.id],
                      owner: this.getController(command[1][0].fullEntity.tags.CONTROLLER),
                      target: target,
                      initialCommand: command[1][0].fullEntity,
                      debugType: 'power 3',
                      debug: this.entities
                    };
                    this.turns[currentTurnNumber].actions[actionIndex] = action;
                  }
                  if (command[1][0].tags) {
                    armor = 0;
                    ref19 = command[1][0].tags;
                    for (w = 0, len12 = ref19.length; w < len12; w++) {
                      tag = ref19[w];
                      if (tag.tag === 'ARMOR' && tag.value > 0) {
                        armor = tag.value;
                      }
                    }
                    if (armor > 0) {
                      action = {
                        turn: currentTurnNumber - 1,
                        index: actionIndex++,
                        timestamp: batch.timestamp,
                        prefix: '\t',
                        type: ': ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.getController(this.entities[command[1][0].attributes.entity].tags.CONTROLLER),
                        initialCommand: command[1][0],
                        debugType: 'armor'
                      };
                      this.turns[currentTurnNumber].actions[actionIndex] = action;
                    }
                  }
                }
              }
            }
          }
        }
      }
      if (parseInt(this.opponent.id) === parseInt(this.mainPlayerId)) {
        this.switchMainPlayer();
      }
      return this.emit('players-ready');
    };

    ReplayPlayer.prototype.switchMainPlayer = function() {
      var tempOpponent;
      tempOpponent = this.player;
      this.player = this.opponent;
      return this.opponent = tempOpponent;
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
