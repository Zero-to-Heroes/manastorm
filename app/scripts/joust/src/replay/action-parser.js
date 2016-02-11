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
      var action, armor, batch, command, dmg, entity, entityTag, excluded, i, info, j, k, l, len, len1, len2, len3, len4, len5, len6, len7, len8, len9, m, meta, n, o, p, playedCard, publicSecret, q, r, ref, ref1, ref10, ref11, ref12, ref13, ref14, ref15, ref16, ref17, ref18, ref19, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, results, s, secret, sortedActions, t, tag, tagValue, target, tempTurnNumber;
      this.players = [this.player, this.opponent];
      this.playerIndex = 0;
      this.turnNumber = 1;
      this.currentPlayer = this.players[this.playerIndex];
      ref = this.history;
      for (i = k = 0, len = ref.length; k < len; i = ++k) {
        batch = ref[i];
        ref1 = batch.commands;
        for (j = l = 0, len1 = ref1.length; l < len1; j = ++l) {
          command = ref1[j];
          this.parseMulliganTurn(batch, command);
          this.parseStartOfTurn(batch, command);
          this.parseDrawCard(batch, command);
          if (command[0] === 'receiveAction') {
            this.currentTurnNumber = this.turnNumber - 1;
            if (this.turns[this.currentTurnNumber]) {
              this.parseMulliganCards(batch, command[1][0]);
              this.parseCardPlayedFromHand(batch, command[1][0]);
              this.parseSecretPlayedFromHand(batch, command[1][0]);
              this.parsePowerEffects(batch, command[1][0]);
              this.parseAttacks(batch, command[1][0]);
              this.parseDeaths(batch, command[1][0]);
              this.parseDiscovers(batch, command[1][0]);
              if (command[1][0].tags && ((ref2 = command[1][0].attributes.type) !== '5' && ref2 !== '7')) {
                playedCard = -1;
                excluded = false;
                secret = false;
                ref3 = command[1][0].tags;
                for (m = 0, len2 = ref3.length; m < len2; m++) {
                  tag = ref3[m];
                  if (tag.tag === 'ZONE' && ((ref4 = tag.value) === 1 || ref4 === 7)) {
                    playedCard = tag.entity;
                  }
                  if (tag.tag === 'SECRET' && tag.value === 1) {
                    secret = true;
                    publicSecret = command[1][0].attributes.type === '7' && this.turns[this.currentTurnNumber].activePlayer.id === this.mainPlayerId;
                  }
                  if (tag.tag === 'ATTACHED') {
                    excluded = true;
                  }
                }
                if (playedCard > -1 && !excluded) {
                  action = {
                    turn: this.currentTurnNumber - 1,
                    timestamp: batch.timestamp,
                    type: ': ',
                    secret: secret,
                    publicSecret: publicSecret,
                    data: this.entities[playedCard],
                    owner: this.turns[this.currentTurnNumber].activePlayer,
                    initialCommand: command[1][0],
                    debugType: 'played card'
                  };
                  this.addAction(this.currentTurnNumber, action);
                }
              }
              if (command[1][0].attributes.entity && command[1][0].attributes.type === '5') {
                entity = this.entities[command[1][0].attributes.entity];
                if (entity.tags.SECRET === 1) {
                  console.log('\tyes', entity, command[1][0]);
                  action = {
                    turn: this.currentTurnNumber - 1,
                    timestamp: batch.timestamp + 0.01,
                    actionType: 'secret-revealed',
                    data: entity,
                    initialCommand: command[1][0]
                  };
                  this.addAction(this.currentTurnNumber, action);
                }
              }
              if (command[1][0].showEntity && (command[1][0].attributes.type === '1' || (((ref5 = command[1][0].attributes.type) !== '3' && ref5 !== '7') && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0)))) {
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
                  for (n = 0, len3 = ref7.length; n < len3; n++) {
                    tag = ref7[n];
                    if (tag.tag === 'ZONE' && tag.value === 1) {
                      playedCard = tag.entity;
                    }
                  }
                }
                if (playedCard > -1) {
                  action = {
                    turn: this.currentTurnNumber - 1,
                    timestamp: batch.timestamp,
                    type: ': ',
                    data: this.entities[command[1][0].showEntity.id] ? this.entities[command[1][0].showEntity.id] : command[1][0].showEntity,
                    owner: this.turns[this.currentTurnNumber].activePlayer,
                    debugType: 'showEntity',
                    debug: command[1][0].showEntity,
                    initialCommand: command[1][0]
                  };
                  if (action.data) {
                    this.addAction(this.currentTurnNumber, action);
                  }
                }
              }
              if (command[1][0].tags && command[1][0].attributes.type === '5') {
                playedCard = -1;
                excluded = false;
                secret = false;
                ref8 = command[1][0].tags;
                for (o = 0, len4 = ref8.length; o < len4; o++) {
                  tag = ref8[o];
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
                    turn: this.currentTurnNumber - 1,
                    timestamp: batch.timestamp,
                    type: ': ',
                    secret: secret,
                    data: this.entities[playedCard],
                    owner: command[1][0].attributes.entity,
                    initialCommand: command[1][0],
                    debugType: 'played card from tigger'
                  };
                  this.addAction(this.currentTurnNumber, action);
                }
              }
              if (command[1][0].tags && ((ref10 = command[1][0].attributes.type) === '5') && ((ref11 = command[1][0].meta) != null ? ref11.length : void 0) > 0) {
                ref12 = command[1][0].meta;
                for (p = 0, len5 = ref12.length; p < len5; p++) {
                  meta = ref12[p];
                  ref13 = meta.info;
                  for (q = 0, len6 = ref13.length; q < len6; q++) {
                    info = ref13[q];
                    if (meta.meta === 'TARGET' && ((ref14 = meta.info) != null ? ref14.length : void 0) > 0 && (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) !== info.entity)) {
                      action = {
                        turn: this.currentTurnNumber - 1,
                        timestamp: batch.timestamp,
                        target: info.entity,
                        type: ': trigger ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.getController(this.entities[command[1][0].attributes.entity].tags.CONTROLLER),
                        initialCommand: command[1][0],
                        debugType: 'trigger effect card'
                      };
                      this.addAction(this.currentTurnNumber, action);
                    }
                  }
                }
              }
              if ((ref15 = command[1][0].attributes.type) === '3' || ref15 === '5') {
                if (!command[1][0].parent || !command[1][0].parent.attributes.target || parseInt(command[1][0].parent.attributes.target) <= 0) {
                  if (command[1][0].tags) {
                    dmg = 0;
                    target = void 0;
                    ref16 = command[1][0].tags;
                    for (r = 0, len7 = ref16.length; r < len7; r++) {
                      tag = ref16[r];
                      if (tag.tag === 'DAMAGE' && tag.value > 0) {
                        dmg = tag.value;
                        target = tag.entity;
                      }
                    }
                    if (dmg > 0 && command[1][0].attributes.type === '5') {
                      action = {
                        turn: this.currentTurnNumber - 1,
                        timestamp: batch.timestamp,
                        prefix: '\t',
                        type: ': ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.turns[this.currentTurnNumber].activePlayer,
                        target: target,
                        initialCommand: command[1][0],
                        debugType: 'power 3 dmg'
                      };
                      this.addAction(this.currentTurnNumber, action);
                    }
                  }
                  if (command[1][0].fullEntity && command[1][0].fullEntity.tags.CARDTYPE !== 6 && !(command[1][0].attributes.type === '3' && ((ref17 = command.fullEntities) != null ? ref17.length : void 0) === 3)) {
                    if (command[1][0].parent) {
                      ref18 = command[1][0].parent.tags;
                      for (s = 0, len8 = ref18.length; s < len8; s++) {
                        tag = ref18[s];
                        if (tag.tag === 'HEROPOWER_ACTIVATIONS_THIS_TURN' && tag.value > 0) {
                          command[1][0].indent = command[1][0].indent > 1 ? command[1][0].indent - 1 : void 0;
                          command[1][0].fullEntity.indent = command[1][0].fullEntity.indent > 1 ? command[1][0].fullEntity.indent - 1 : void 0;
                        }
                      }
                    }
                    action = {
                      turn: this.currentTurnNumber - 1,
                      timestamp: batch.timestamp,
                      prefix: '\t',
                      type: ': ',
                      data: this.entities[command[1][0].attributes.entity],
                      owner: this.turns[this.currentTurnNumber].activePlayer,
                      initialCommand: command[1][0],
                      debugType: 'power 3 root'
                    };
                    this.addAction(this.currentTurnNumber, action);
                    action = {
                      turn: this.currentTurnNumber - 1,
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
                    this.addAction(this.currentTurnNumber, action);
                  }
                  if (command[1][0].tags) {
                    armor = 0;
                    ref19 = command[1][0].tags;
                    for (t = 0, len9 = ref19.length; t < len9; t++) {
                      tag = ref19[t];
                      if (tag.tag === 'ARMOR' && tag.value > 0) {
                        armor = tag.value;
                      }
                    }
                    if (armor > 0) {
                      action = {
                        turn: this.currentTurnNumber - 1,
                        timestamp: batch.timestamp,
                        prefix: '\t',
                        type: ': ',
                        data: this.entities[command[1][0].attributes.entity],
                        owner: this.getController(this.entities[command[1][0].attributes.entity].tags.CONTROLLER),
                        initialCommand: command[1][0],
                        debugType: 'armor'
                      };
                      this.addAction(this.currentTurnNumber, action);
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

    ActionParser.prototype.parseMulliganTurn = function(batch, command) {
      if (command[0] === 'receiveTagChange' && command[1][0].entity === 2 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
        this.turns[this.turnNumber] = {
          turn: 'Mulligan',
          playerMulligan: [],
          opponentMulligan: [],
          timestamp: batch.timestamp,
          actions: []
        };
        this.turns.length++;
        this.turnNumber++;
        this.currentPlayer = this.players[++this.playerIndex % 2];
      }
      if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 3 && command[1][0].tag === 'MULLIGAN_STATE' && command[1][0].value === 1) {
        return this.currentPlayer = this.players[++this.playerIndex % 2];
      }
    };

    ActionParser.prototype.parseStartOfTurn = function(batch, command) {
      if (command[0] === 'receiveTagChange' && command[1].length > 0 && command[1][0].entity === 1 && command[1][0].tag === 'STEP' && command[1][0].value === 6) {
        this.turns[this.turnNumber] = {
          turn: this.turnNumber - 1,
          timestamp: batch.timestamp,
          actions: [],
          activePlayer: this.currentPlayer
        };
        this.turns.length++;
        this.turnNumber++;
        return this.currentPlayer = this.players[++this.playerIndex % 2];
      }
    };

    ActionParser.prototype.parseDrawCard = function(batch, command) {
      var action, currentCommand, entity, owner, ownerId, ref, ref1;
      if (command[0] === 'receiveTagChange' && command[1][0].tag === 'ZONE' && command[1][0].value === 3) {
        if (this.currentTurnNumber >= 2) {
          currentCommand = command[1][0];
          while (currentCommand.parent && ((ref = currentCommand.entity) !== '2' && ref !== '3')) {
            currentCommand = currentCommand.parent;
          }
          ownerId = currentCommand.attributes.entity;
          if (ownerId !== '2' && ownerId !== '3') {
            owner = this.getController(this.entities[ownerId].tags.CONTROLLER);
          } else {
            owner = this.entities[ownerId];
          }
          action = {
            turn: this.currentTurnNumber,
            timestamp: batch.timestamp,
            actionType: 'card-draw',
            type: ' draws ',
            data: this.entities[command[1][0].entity],
            owner: owner,
            initialCommand: command[1][0]
          };
          this.addAction(this.currentTurnNumber, action);
        }
      }
      if (command[0] === 'receiveAction' && (command[1][0].type = '5')) {
        if (this.currentTurnNumber >= 2) {
          entity = command[1][0].showEntity || command[1][0].fullEntity;
          if (entity && entity.tags.ZONE === 3) {
            currentCommand = command[1][0];
            while (currentCommand.parent && ((ref1 = currentCommand.entity) !== '2' && ref1 !== '3')) {
              currentCommand = currentCommand.parent;
            }
            action = {
              turn: this.currentTurnNumber,
              timestamp: batch.timestamp,
              actionType: 'card-draw',
              type: ' draws ',
              data: this.entities[entity.id],
              owner: this.entities[currentCommand.attributes.entity],
              initialCommand: command[1][0]
            };
            return this.addAction(this.currentTurnNumber, action);
          }
        }
      }
    };

    ActionParser.prototype.parseMulliganCards = function(batch, command) {
      var k, len, mulliganed, ref, results, tag;
      if (command.attributes.type === '5' && this.currentTurnNumber === 1 && command.hideEntities) {
        this.turns[this.currentTurnNumber].playerMulligan = command.hideEntities;
      }
      if (command.attributes.type === '5' && this.currentTurnNumber === 1 && command.attributes.entity !== this.mainPlayerId) {
        mulliganed = [];
        ref = command.tags;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          tag = ref[k];
          if (tag.tag === 'ZONE' && tag.value === 2) {
            results.push(this.turns[this.currentTurnNumber].opponentMulligan.push(tag.entity));
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    };

    ActionParser.prototype.parseCardPlayedFromHand = function(batch, command) {
      var action, entity, k, len, playedCard, ref, tag;
      if (command.attributes.type === '7') {
        entity = this.entities[command.attributes.entity];
        playedCard = -1;
        ref = command.tags;
        for (k = 0, len = ref.length; k < len; k++) {
          tag = ref[k];
          if (tag.tag === 'ZONE' && tag.value === 1) {
            playedCard = tag.entity;
          }
        }
        if (playedCard < 0 && command.showEntity) {
          if (command.showEntity.tags.ZONE === 1) {
            playedCard = command.showEntity.id;
          }
        }
        if (playedCard > -1) {
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: batch.timestamp,
            actionType: 'played-card-from-hand',
            data: this.entities[playedCard],
            owner: this.turns[this.currentTurnNumber].activePlayer,
            initialCommand: command
          };
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    ActionParser.prototype.parseSecretPlayedFromHand = function(batch, command) {
      var action, k, len, playedCard, publicSecret, ref, secret, tag;
      if (command.attributes.type === '7') {
        playedCard = -1;
        secret = false;
        ref = command.tags;
        for (k = 0, len = ref.length; k < len; k++) {
          tag = ref[k];
          if (tag.tag === 'ZONE' && tag.value === 7) {
            playedCard = tag.entity;
          }
          if (tag.tag === 'SECRET' && tag.value === 1) {
            secret = true;
            publicSecret = this.turns[this.currentTurnNumber].activePlayer.id === this.mainPlayerId;
          }
        }
        if (playedCard > -1 && secret) {
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: batch.timestamp,
            actionType: 'played-secret-from-hand',
            publicSecret: publicSecret,
            data: this.entities[playedCard],
            owner: this.turns[this.currentTurnNumber].activePlayer,
            initialCommand: command
          };
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    ActionParser.prototype.parsePowerEffects = function(batch, command) {
      var action, info, k, len, mainAction, meta, ref, ref1, ref2, ref3, results, sameOwnerAsParent;
      if (command.attributes.type === '3' && ((ref = command.meta) != null ? ref.length : void 0) > 0) {
        console.log('\tConsidering power of', command);
        if (((ref1 = command.parent) != null ? (ref2 = ref1.attributes) != null ? ref2.entity : void 0 : void 0) === command.attributes.entity) {
          sameOwnerAsParent = true;
        }
        if (command.parent) {
          mainAction = command.parent;
        }
        ref3 = command.meta;
        results = [];
        for (k = 0, len = ref3.length; k < len; k++) {
          meta = ref3[k];
          results.push((function() {
            var l, len1, ref4, results1;
            ref4 = meta.info;
            results1 = [];
            for (l = 0, len1 = ref4.length; l < len1; l++) {
              info = ref4[l];
              if (meta.meta === 'DAMAGE') {
                action = {
                  turn: this.currentTurnNumber - 1,
                  timestamp: batch.timestamp,
                  target: info.entity,
                  amount: meta.data,
                  mainAction: mainAction,
                  sameOwnerAsParent: sameOwnerAsParent,
                  actionType: 'power-damage',
                  data: this.entities[command.attributes.entity],
                  owner: this.getController(this.entities[command.attributes.entity].tags.CONTROLLER),
                  initialCommand: command
                };
                results1.push(this.addAction(this.currentTurnNumber, action));
              } else {
                results1.push(void 0);
              }
            }
            return results1;
          }).call(this));
        }
        return results;
      }
    };

    ActionParser.prototype.parseAttacks = function(batch, command) {
      var action;
      if (command.attributes.type === '1') {
        action = {
          turn: this.currentTurnNumber - 1,
          timestamp: batch.timestamp,
          actionType: 'attack',
          data: this.entities[command.attributes.entity],
          owner: this.turns[this.currentTurnNumber].activePlayer,
          target: command.attributes.target,
          initialCommand: command
        };
        return this.addAction(this.currentTurnNumber, action);
      }
    };

    ActionParser.prototype.parseDeaths = function(batch, command) {
      var action, k, len, ref, results, tag;
      if (command.tags && command.attributes.type === '6') {
        ref = command.tags;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          tag = ref[k];
          if (tag.tag === 'ZONE' && tag.value === 4) {
            action = {
              turn: this.currentTurnNumber - 1,
              timestamp: batch.timestamp,
              actionType: 'minion-death',
              data: tag.entity,
              initialCommand: command
            };
            results.push(this.addAction(this.currentTurnNumber, action));
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    };

    ActionParser.prototype.parseDiscovers = function(batch, command) {
      var action, choices, entity, isDiscover, k, len, ref, ref1;
      if (command.attributes.type === '3' && ((ref = command.fullEntities) != null ? ref.length : void 0) === 3) {
        console.log('Considering Discover action', command);
        isDiscover = true;
        choices = [];
        ref1 = command.fullEntities;
        for (k = 0, len = ref1.length; k < len; k++) {
          entity = ref1[k];
          console.log('\tExamining discovered entity', entity);
          choices.push(entity);
          if (entity.tags.ZONE !== 6) {
            isDiscover = false;
          }
        }
        if (isDiscover) {
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: batch.timestamp,
            actionType: 'discover',
            data: this.entities[command.attributes.entity],
            choices: choices,
            initialCommand: command
          };
          command.isDiscover = true;
          console.log('\t\tadding Discover action', action);
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    return ActionParser;

  })(EventEmitter);

  module.exports = ActionParser;

}).call(this);
