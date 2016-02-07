(function() {
  var ActionParser, Entity, EventEmitter, HistoryBatch, Player, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Entity = require('./entity');

  Player = require('./player');

  HistoryBatch = require('./history-batch');

  _ = require('lodash');

  EventEmitter = require('events');

  ActionParser = (function(superClass) {
    extend(ActionParser, superClass);

    function ActionParser(replay) {
      this.replay = replay;
      EventEmitter.call(this);
      this.player = this.replay.player;
      this.opponent = this.replay.opponent;
      this.mainPlayerId = this.replay.mainPlayerId;
      this.history = this.replay.history;
      this.entities = this.replay.entities;
      this.turns = this.replay.turns;
      this.getController = this.replay.getController;
    }

    ActionParser.prototype.populateEntities = function() {
      var actionIndex, batch, command, currentPlayer, definition, entity, i, j, k, l, len, len1, len2, m, playerIndex, players, ref, ref1, ref2, results, turnNumber;
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
      ref2 = this.history;
      results = [];
      for (i = m = 0, len2 = ref2.length; m < len2; i = ++m) {
        batch = ref2[i];
        results.push((function() {
          var len3, n, ref3, results1;
          ref3 = batch.commands;
          results1 = [];
          for (j = n = 0, len3 = ref3.length; n < len3; j = ++n) {
            command = ref3[j];
            if (command[0] === 'receiveTagChange') {
              if (command[1][0].tag === 'SECRET' && command[1][0].value === 1) {
                this.entities[command[1][0].entity].tags[command[1][0].tag] = command[1][0].value;
              }
            }
            if (command[0] === 'receiveShowEntity') {
              if (command[1][0].tags.SECRET === 1) {
                results1.push(this.entities[command[1][0].id].tags.SECRET = 1);
              } else {
                results1.push(void 0);
              }
            } else {
              results1.push(void 0);
            }
          }
          return results1;
        }).call(this));
      }
      return results;
    };

    ActionParser.prototype.parseActions = function() {
      var action, armor, batch, command, currentCommand, currentPlayer, currentTurnNumber, dmg, entity, entityTag, excluded, i, info, j, k, l, len, len1, len10, len11, len2, len3, len4, len5, len6, len7, len8, len9, m, meta, mulliganed, n, o, p, playedCard, playerIndex, players, publicSecret, q, r, ref, ref1, ref10, ref11, ref12, ref13, ref14, ref15, ref16, ref17, ref18, ref19, ref2, ref20, ref3, ref4, ref5, ref6, ref7, ref8, ref9, results, s, secret, sortedActions, t, tag, tagValue, target, tempTurnNumber, turnNumber, u, v;
      players = [this.player, this.opponent];
      playerIndex = 0;
      turnNumber = 1;
      currentPlayer = players[playerIndex];
      ref = this.history;
      for (i = k = 0, len = ref.length; k < len; i = ++k) {
        batch = ref[i];
        ref1 = batch.commands;
        for (j = l = 0, len1 = ref1.length; l < len1; j = ++l) {
          command = ref1[j];
          if (command[0] === 'receiveTagChange' && command[1][0].entity === 2 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
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
            currentPlayer = players[++playerIndex % 2];
          }
          if (command[0] === 'receiveTagChange' && command[1][0].tag === 'ZONE' && command[1][0].value === 3) {
            if (currentTurnNumber >= 2) {
              currentCommand = command[1][0];
              console.log('currentCommand', currentCommand);
              while (currentCommand.parent && ((ref2 = currentCommand.entity) !== '2' && ref2 !== '3')) {
                currentCommand = currentCommand.parent;
              }
              if (!currentCommand) {
                console.warn('no one drew this card????', command[1][0]);
              }
              action = {
                turn: currentTurnNumber,
                timestamp: batch.timestamp,
                actionType: 'card-draw',
                type: ' draws ',
                data: this.entities[command[1][0].entity],
                owner: this.entities[currentCommand.attributes.entity],
                initialCommand: command[1][0]
              };
              this.addAction(currentTurnNumber, action);
            }
          }
          if (command[0] === 'receiveAction' && (command[1][0].type = '5' && command[1][0].showEntity)) {
            if (currentTurnNumber >= 2) {
              if (command[1][0].showEntity.tags.ZONE === 3) {
                currentCommand = command[1][0];
                while (currentCommand.parent && ((ref3 = currentCommand.entity) !== '2' && ref3 !== '3')) {
                  currentCommand = currentCommand.parent;
                }
                if (!currentCommand) {
                  console.warn('no one drew this card????', command[1][0]);
                }
                console.log('about to add draw card action', command[1][0], currentCommand);
                action = {
                  turn: currentTurnNumber,
                  timestamp: batch.timestamp,
                  actionType: 'card-draw',
                  type: ' draws ',
                  data: this.entities[command[1][0].showEntity.id],
                  owner: this.entities[currentCommand.attributes.entity],
                  initialCommand: command[1][0]
                };
                this.addAction(currentTurnNumber, action);
              }
            }
          }
          if (command[0] === 'receiveAction') {
            currentTurnNumber = turnNumber - 1;
            if (this.turns[currentTurnNumber]) {
              if (command[1][0].attributes.type === '5' && currentTurnNumber === 1 && command[1][0].hideEntities) {
                this.turns[currentTurnNumber].playerMulligan = command[1][0].hideEntities;
              }
              if (command[1][0].attributes.type === '5' && currentTurnNumber === 1 && command[1][0].attributes.entity !== this.mainPlayerId) {
                mulliganed = [];
                ref4 = command[1][0].tags;
                for (m = 0, len2 = ref4.length; m < len2; m++) {
                  tag = ref4[m];
                  if (tag.tag === 'ZONE' && tag.value === 2) {
                    console.log('adding mulligan for oppoentn', tag, command[1][0]);
                    this.turns[currentTurnNumber].opponentMulligan.push(tag.entity);
                  }
                }
              }
              if (command[1][0].tags && command[1][0].attributes.type !== '5') {
                playedCard = -1;
                excluded = false;
                secret = false;
                ref5 = command[1][0].tags;
                for (n = 0, len3 = ref5.length; n < len3; n++) {
                  tag = ref5[n];
                  if (tag.tag === 'ZONE' && ((ref6 = tag.value) === 1 || ref6 === 7)) {
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
                    timestamp: batch.timestamp,
                    type: ': ',
                    secret: secret,
                    publicSecret: publicSecret,
                    data: this.entities[playedCard],
                    owner: this.turns[currentTurnNumber].activePlayer,
                    initialCommand: command[1][0],
                    debugType: 'played card'
                  };
                  this.addAction(currentTurnNumber, action);
                }
              }
              if (command[1][0].attributes.entity && command[1][0].attributes.type === '5') {
                entity = this.entities[command[1][0].attributes.entity];
                if (entity.tags.SECRET === 1) {
                  console.log('\tyes', entity, command[1][0]);
                  action = {
                    turn: currentTurnNumber - 1,
                    timestamp: batch.timestamp + 0.01,
                    actionType: 'secret-revealed',
                    data: entity,
                    initialCommand: command[1][0]
                  };
                  this.addAction(currentTurnNumber, action);
                }
              }
              if (command[1][0].showEntity && (command[1][0].attributes.type === '1' || (command[1][0].attributes.type !== '3' && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)))) {
                playedCard = -1;
                if (command[1][0].showEntity.tags) {
                  ref7 = command[1][0].showEntity.tags;
                  for (entityTag in ref7) {
                    tagValue = ref7[entityTag];
                    if (entityTag === 'ZONE' && tagValue === 1) {
                      playedCard = command[1][0].showEntity.id;
                    }
                  }
                }
                if (command[1][0].tags) {
                  ref8 = command[1][0].tags;
                  for (o = 0, len4 = ref8.length; o < len4; o++) {
                    tag = ref8[o];
                    if (tag.tag === 'ZONE' && tag.value === 1) {
                      playedCard = tag.entity;
                    }
                  }
                }
                if (playedCard > -1) {
                  action = {
                    turn: currentTurnNumber - 1,
                    timestamp: batch.timestamp,
                    type: ': ',
                    data: this.entities[command[1][0].showEntity.id] ? this.entities[command[1][0].showEntity.id] : command[1][0].showEntity,
                    owner: this.turns[currentTurnNumber].activePlayer,
                    debugType: 'showEntity',
                    debug: command[1][0].showEntity,
                    initialCommand: command[1][0]
                  };
                  if (action.data) {
                    this.addAction(currentTurnNumber, action);
                  }
                }
              }
              if (command[1][0].tags && command[1][0].attributes.type === '5') {
                playedCard = -1;
                excluded = false;
                secret = false;
                ref9 = command[1][0].tags;
                for (p = 0, len5 = ref9.length; p < len5; p++) {
                  tag = ref9[p];
                  if (tag.tag === 'ZONE' && ((ref10 = tag.value) === 1 || ref10 === 7)) {
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
                    timestamp: batch.timestamp,
                    type: ': ',
                    secret: secret,
                    data: this.entities[playedCard],
                    owner: command[1][0].attributes.entity,
                    initialCommand: command[1][0],
                    debugType: 'played card from tigger'
                  };
                  this.addAction(currentTurnNumber, action);
                }
              }
              if (command[1][0].tags && ((ref11 = command[1][0].attributes.type) === '3' || ref11 === '5') && ((ref12 = command[1][0].meta) != null ? ref12.length : void 0) > 0) {
                ref13 = command[1][0].meta;
                for (q = 0, len6 = ref13.length; q < len6; q++) {
                  meta = ref13[q];
                  ref14 = meta.info;
                  for (r = 0, len7 = ref14.length; r < len7; r++) {
                    info = ref14[r];
                    if (meta.meta === 'TARGET' && ((ref15 = meta.info) != null ? ref15.length : void 0) > 0 && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) !== info.entity)) {
                      action = {
                        turn: currentTurnNumber - 1,
                        timestamp: batch.timestamp,
                        target: info.entity,
                        type: ': trigger ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.getController(this.entities[command[1][0].attributes.entity].tags.CONTROLLER),
                        initialCommand: command[1][0],
                        debugType: 'trigger effect card'
                      };
                      this.addAction(currentTurnNumber, action);
                    }
                  }
                }
              }
              if (command[1][0].tags && command[1][0].attributes.type === '6') {
                ref16 = command[1][0].tags;
                for (s = 0, len8 = ref16.length; s < len8; s++) {
                  tag = ref16[s];
                  if (tag.tag === 'ZONE' && tag.value === 4) {
                    action = {
                      turn: currentTurnNumber - 1,
                      timestamp: batch.timestamp,
                      type: ' died ',
                      owner: tag.entity,
                      initialCommand: command[1][0]
                    };
                    this.addAction(currentTurnNumber, action);
                  }
                }
              }
              if (parseInt(command[1][0].attributes.target) > 0 && (command[1][0].attributes.type === '1' || !command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)) {
                action = {
                  turn: currentTurnNumber - 1,
                  timestamp: batch.timestamp,
                  type: ': ',
                  actionType: 'attack',
                  data: this.entities[command[1][0].attributes.entity],
                  owner: this.turns[currentTurnNumber].activePlayer,
                  target: command[1][0].attributes.target,
                  initialCommand: command[1][0],
                  debugType: 'attack with complex conditions'
                };
                this.addAction(currentTurnNumber, action);
              }
              if ((ref17 = command[1][0].attributes.type) === '3' || ref17 === '5') {
                if (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0) {
                  if (command[1][0].tags) {
                    dmg = 0;
                    target = void 0;
                    ref18 = command[1][0].tags;
                    for (t = 0, len9 = ref18.length; t < len9; t++) {
                      tag = ref18[t];
                      if (tag.tag === 'DAMAGE' && tag.value > 0) {
                        dmg = tag.value;
                        target = tag.entity;
                      }
                    }
                    if (dmg > 0) {
                      action = {
                        turn: currentTurnNumber - 1,
                        timestamp: batch.timestamp,
                        prefix: '\t',
                        type: ': ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.turns[currentTurnNumber].activePlayer,
                        target: target,
                        initialCommand: command[1][0],
                        debugType: 'power 3 dmg'
                      };
                      this.addAction(currentTurnNumber, action);
                    }
                  }
                  if (command[1][0].fullEntity && command[1][0].fullEntity.tags.CARDTYPE !== 6) {
                    if (command[1][0].parent) {
                      ref19 = command[1][0].parent.tags;
                      for (u = 0, len10 = ref19.length; u < len10; u++) {
                        tag = ref19[u];
                        if (tag.tag === 'HEROPOWER_ACTIVATIONS_THIS_TURN' && tag.value > 0) {
                          command[1][0].indent = command[1][0].indent > 1 ? command[1][0].indent - 1 : void 0;
                          command[1][0].fullEntity.indent = command[1][0].fullEntity.indent > 1 ? command[1][0].fullEntity.indent - 1 : void 0;
                        }
                      }
                    }
                    action = {
                      turn: currentTurnNumber - 1,
                      timestamp: batch.timestamp,
                      prefix: '\t',
                      type: ': ',
                      data: this.entities[command[1][0].attributes.entity],
                      owner: this.turns[currentTurnNumber].activePlayer,
                      initialCommand: command[1][0],
                      debugType: 'power 3 root'
                    };
                    this.addAction(currentTurnNumber, action);
                    action = {
                      turn: currentTurnNumber - 1,
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
                    this.addAction(currentTurnNumber, action);
                  }
                  if (command[1][0].tags) {
                    armor = 0;
                    ref20 = command[1][0].tags;
                    for (v = 0, len11 = ref20.length; v < len11; v++) {
                      tag = ref20[v];
                      if (tag.tag === 'ARMOR' && tag.value > 0) {
                        armor = tag.value;
                      }
                    }
                    if (armor > 0) {
                      action = {
                        turn: currentTurnNumber - 1,
                        timestamp: batch.timestamp,
                        prefix: '\t',
                        type: ': ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.getController(this.entities[command[1][0].attributes.entity].tags.CONTROLLER),
                        initialCommand: command[1][0],
                        debugType: 'armor'
                      };
                      this.addAction(currentTurnNumber, action);
                    }
                  }
                }
              }
            }
          }
        }
      }
      tempTurnNumber = 1;
      results = [];
      while (this.turns[tempTurnNumber]) {
        sortedActions = _.sortBy(this.turns[tempTurnNumber].actions, 'timestamp');
        this.turns[tempTurnNumber].actions = sortedActions;
        results.push(tempTurnNumber++);
      }
      return results;
    };

    ActionParser.prototype.addAction = function(currentTurnNumber, action) {
      if (action.initialCommand.parent && action.initialCommand.parent.timestamp === action.timestamp) {
        action.timestamp += 0.01;
      }
      return this.turns[currentTurnNumber].actions.push(action);
    };

    return ActionParser;

  })(EventEmitter);

  module.exports = ActionParser;

}).call(this);
