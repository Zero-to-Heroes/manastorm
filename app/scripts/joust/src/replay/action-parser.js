(function() {
  var ActionParser, Entity, EventEmitter, HistoryBatch, Player, _, tsToSeconds,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Entity = require('./entity');

  Player = require('./player');

  HistoryBatch = require('./history-batch');

  _ = require('lodash');

  EventEmitter = require('events');

  tsToSeconds = function(ts) {
    var hours, minutes, parts, seconds;
    parts = ts != null ? typeof ts.split === "function" ? ts.split(':') : void 0 : void 0;
    if (!parts) {
      return null;
    }
    hours = parseInt(parts[0]) * 60 * 60;
    minutes = parseInt(parts[1]) * 60;
    seconds = parseFloat(parts[2]);
    return hours + minutes + seconds;
  };

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
      var batch, command, i, j, k, l, len, len1, ref, ref1, results, sortedActions, tempTurnNumber;
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
              this.parseSecretRevealed(batch, command[1][0]);
              this.parseMulliganCards(batch, command[1][0]);
              this.parseCardPlayedFromHand(batch, command[1][0]);
              this.parseHeroPowerUsed(batch, command[1][0]);
              this.parseSecretPlayedFromHand(batch, command[1][0]);
              this.parseAttacks(batch, command[1][0]);
              this.parsePowerEffects(batch, command[1][0]);
              this.parseDeaths(batch, command[1][0]);
              this.parseDiscovers(batch, command[1][0]);
              this.parseSummons(batch, command[1][0]);
              this.parseEquipEffect(batch, command[1][0]);
              this.parseTriggerFullEntityCreation(batch, command[1][0]);
              this.parseTriggerPutSecretInPlay(batch, command[1][0]);
              this.parseNewHeroPower(batch, command[1][0]);
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
      var action, currentCommand, entity, owner, ownerId, ref, ref1, ref2, ref3;
      currentCommand = command[1][0];
      if (command[0] === 'receiveTagChange' && command[1][0].tag === 'ZONE' && command[1][0].value === 3) {
        if (this.currentTurnNumber >= 2) {
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
            type: 'from tag change',
            data: this.entities[command[1][0].entity],
            mainAction: (ref1 = command[1][0].parent) != null ? ref1.parent : void 0,
            owner: owner,
            initialCommand: command[1][0]
          };
          this.addAction(this.currentTurnNumber, action);
        }
      }
      if (command[0] === 'receiveAction') {
        if (this.currentTurnNumber >= 2) {
          while (currentCommand.parent && ((ref2 = currentCommand.entity) !== '2' && ref2 !== '3')) {
            currentCommand = currentCommand.parent;
          }
          ownerId = currentCommand.attributes.entity;
          if (ownerId !== '2' && ownerId !== '3') {
            owner = this.getController(this.entities[ownerId].tags.CONTROLLER);
          } else {
            owner = this.entities[ownerId];
          }
          entity = command[1][0].showEntity || command[1][0].fullEntity;
          if (entity && entity.tags.ZONE === 3) {
            currentCommand = command[1][0];
            while (currentCommand.parent && ((ref3 = currentCommand.entity) !== '2' && ref3 !== '3')) {
              currentCommand = currentCommand.parent;
            }
            action = {
              turn: this.currentTurnNumber,
              timestamp: batch.timestamp,
              actionType: 'card-draw',
              type: 'from action',
              data: this.entities[entity.id],
              mainAction: command[1][0].parent,
              owner: owner,
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
            if (this.entities[tag.entity].tags.CARDTYPE !== 6) {
              playedCard = tag.entity;
            }
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
            timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
            actionType: 'played-card-from-hand',
            data: this.entities[playedCard],
            owner: this.turns[this.currentTurnNumber].activePlayer,
            initialCommand: command
          };
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    ActionParser.prototype.parseNewHeroPower = function(batch, command) {
      var action, card, entity, k, len, ref, ref1, results, tag;
      if (((ref = command.attributes.type) === '3' || ref === '5') && command.tags) {
        ref1 = command.tags;
        results = [];
        for (k = 0, len = ref1.length; k < len; k++) {
          tag = ref1[k];
          if (tag.tag === 'ZONE' && tag.value === 1) {
            entity = this.entities[tag.entity];
            card = this.replay.cardUtils.getCard(entity['cardID']);
            if (card.type === 'Hero Power') {
              action = {
                turn: this.currentTurnNumber - 1,
                timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
                actionType: 'new-hero-power',
                data: entity,
                owner: this.getController(entity.tags.CONTROLLER),
                initialCommand: command
              };
              console.log('receving a new hero power', action);
              results.push(this.addAction(this.currentTurnNumber, action));
            } else {
              results.push(void 0);
            }
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    };

    ActionParser.prototype.parseHeroPowerUsed = function(batch, command) {
      var action, entity;
      if (command.attributes.type === '7') {
        entity = this.entities[command.attributes.entity];
        if (entity.tags.CARDTYPE === 10) {
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
            actionType: 'hero-power',
            data: entity,
            owner: this.getController(entity.tags.CONTROLLER),
            initialCommand: command
          };
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    ActionParser.prototype.parseSecretPlayedFromHand = function(batch, command) {
      var action, entity, k, len, owner, playedCard, ref, secret, tag;
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
          }
        }
        if (playedCard > -1 && secret) {
          entity = this.entities[playedCard];
          owner = this.getController(entity.tags.CONTROLLER);
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
            actionType: 'played-secret-from-hand',
            data: entity,
            owner: owner,
            initialCommand: command
          };
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    ActionParser.prototype.parsePowerEffects = function(batch, command) {
      var action, info, k, len, mainAction, meta, ref, ref1, ref2, ref3, ref4, results, sameOwnerAsParent;
      if (((ref = command.attributes.type) === '3' || ref === '5') && ((ref1 = command.meta) != null ? ref1.length : void 0) > 0) {
        if (((ref2 = command.parent) != null ? (ref3 = ref2.attributes) != null ? ref3.entity : void 0 : void 0) === command.attributes.entity) {
          sameOwnerAsParent = true;
        }
        if (command.parent) {
          mainAction = command.parent;
        }
        ref4 = command.meta;
        results = [];
        for (k = 0, len = ref4.length; k < len; k++) {
          meta = ref4[k];
          results.push((function() {
            var l, len1, ref5, results1;
            ref5 = meta.info;
            results1 = [];
            for (l = 0, len1 = ref5.length; l < len1; l++) {
              info = ref5[l];
              if (meta.meta === 'DAMAGE') {
                action = {
                  turn: this.currentTurnNumber - 1,
                  timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp,
                  target: info.entity,
                  amount: meta.data,
                  mainAction: mainAction,
                  sameOwnerAsParent: sameOwnerAsParent,
                  actionType: 'power-damage',
                  data: this.entities[command.attributes.entity],
                  owner: this.getController(this.entities[command.attributes.entity].tags.CONTROLLER),
                  initialCommand: command
                };
                this.addAction(this.currentTurnNumber, action);
              }
              if (meta.meta === 'TARGET') {
                action = {
                  turn: this.currentTurnNumber - 1,
                  timestamp: meta.ts || tsToSeconds(command.attributes.ts) || batch.timestamp,
                  target: info.entity,
                  mainAction: mainAction,
                  sameOwnerAsParent: sameOwnerAsParent,
                  actionType: 'power-target',
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

    ActionParser.prototype.parseTriggerPutSecretInPlay = function(batch, command) {
      var action, entity, k, len, ref, ref1, secretsPutInPlay, tag;
      if ((ref = command.attributes.type) === '3' || ref === '5') {
        secretsPutInPlay = [];
        if (command.tags) {
          ref1 = command.tags;
          for (k = 0, len = ref1.length; k < len; k++) {
            tag = ref1[k];
            if (tag.tag === 'ZONE' && tag.value === 7) {
              entity = this.entities[tag.entity];
              secretsPutInPlay.push(entity);
            }
          }
          if (secretsPutInPlay.length > 0) {
            action = {
              turn: this.currentTurnNumber - 1,
              timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
              secrets: secretsPutInPlay,
              mainAction: command.parent,
              actionType: 'trigger-secret-play',
              data: this.entities[command.attributes.entity],
              owner: this.getController(this.entities[command.attributes.entity].tags.CONTROLLER),
              initialCommand: command
            };
            return this.addAction(this.currentTurnNumber, action);
          }
        }
      }
    };

    ActionParser.prototype.parseTriggerFullEntityCreation = function(batch, command) {
      var action, fullEntities, ref, ref1;
      if ((ref = command.attributes.type) === '5') {
        if (((ref1 = command.fullEntities) != null ? ref1.length : void 0) > 0) {
          fullEntities = _.filter(command.fullEntities, function(entity) {
            return entity.tags.ZONE === 1;
          });
          if ((fullEntities != null ? fullEntities.length : void 0) > 0) {
            action = {
              turn: this.currentTurnNumber - 1,
              timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
              actionType: 'trigger-fullentity',
              data: this.entities[command.attributes.entity],
              owner: this.getController(this.entities[command.attributes.entity].tags.CONTROLLER),
              newEntities: fullEntities,
              initialCommand: command
            };
            return this.addAction(this.currentTurnNumber, action);
          }
        }
      }
    };

    ActionParser.prototype.parseAttacks = function(batch, command) {
      var action;
      if (command.attributes.type === '1') {
        action = {
          turn: this.currentTurnNumber - 1,
          timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
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
              timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
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
        isDiscover = true;
        choices = [];
        ref1 = command.fullEntities;
        for (k = 0, len = ref1.length; k < len; k++) {
          entity = ref1[k];
          choices.push(entity);
          if (entity.tags.ZONE !== 6) {
            isDiscover = false;
          }
        }
        if (isDiscover) {
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
            actionType: 'discover',
            data: this.entities[command.attributes.entity],
            owner: this.getController(this.entities[command.attributes.entity].tags.CONTROLLER),
            choices: choices,
            initialCommand: command
          };
          command.isDiscover = true;
          console.log('adding discover action', action);
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    ActionParser.prototype.parseSummons = function(batch, command) {
      var action, entity, k, len, mainAction, ref, ref1, results;
      if (command.attributes.type === '3' && ((ref = command.fullEntities) != null ? ref.length : void 0) > 0) {
        ref1 = command.fullEntities;
        results = [];
        for (k = 0, len = ref1.length; k < len; k++) {
          entity = ref1[k];
          if (entity.tags.ZONE === 1 && entity.tags.CARDTYPE === 4) {
            if (command.parent) {
              mainAction = command.parent;
            }
            action = {
              turn: this.currentTurnNumber - 1,
              timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
              actionType: 'summon-minion',
              data: entity,
              owner: this.getController(entity.tags.CONTROLLER),
              mainAction: mainAction,
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

    ActionParser.prototype.parseEquipEffect = function(batch, command) {
      var action, entity, k, len, mainAction, ref, ref1, results;
      if (command.attributes.type === '3' && ((ref = command.fullEntities) != null ? ref.length : void 0) > 0) {
        ref1 = command.fullEntities;
        results = [];
        for (k = 0, len = ref1.length; k < len; k++) {
          entity = ref1[k];
          if (entity.tags.ZONE === 1 && entity.tags.CARDTYPE === 7) {
            if (command.parent) {
              mainAction = command.parent;
            }
            action = {
              turn: this.currentTurnNumber - 1,
              timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
              actionType: 'summon-weapon',
              data: entity,
              owner: this.getController(entity.tags.CONTROLLER),
              mainAction: mainAction,
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

    ActionParser.prototype.parseSecretRevealed = function(batch, command) {
      var action, entity, ref;
      if (command.attributes.type === '5') {
        entity = this.entities[command.attributes.entity];
        if ((entity != null ? (ref = entity.tags) != null ? ref.SECRET : void 0 : void 0) === 1) {
          action = {
            turn: this.currentTurnNumber - 1,
            timestamp: tsToSeconds(command.attributes.ts) || batch.timestamp,
            actionType: 'secret-revealed',
            data: entity,
            initialCommand: command
          };
          return this.addAction(this.currentTurnNumber, action);
        }
      }
    };

    return ActionParser;

  })(EventEmitter);

  module.exports = ActionParser;

}).call(this);
