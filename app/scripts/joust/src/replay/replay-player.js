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
      console.log('player constructed');
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
      this.startTime = (new Date).getTime();
      this.currentReplayTime = 0;
      this.started = false;
      this.speed = 1;
      return this.parser.parse(this);
    };

    ReplayPlayer.prototype.run = function() {
      console.log('running player');
      console.log('parsed game');
      this.frequency = 200;
      this.speed = this.initialSpeed || 1;
      return this.interval = setInterval(((function(_this) {
        return function() {
          return _this.update();
        };
      })(this)), this.frequency);
    };

    ReplayPlayer.prototype.start = function(timestamp) {
      console.log('starting game at timestamp', timestamp);
      this.startTimestamp = timestamp;
      return this.started = true;
    };

    ReplayPlayer.prototype.pause = function() {
      console.log('pausing in replay-plyaer');
      this.initialSpeed = this.speed;
      return this.speed = 0;
    };

    ReplayPlayer.prototype.changeSpeed = function(speed) {
      console.log('changing speed in replay', speed);
      return this.speed = speed;
    };

    ReplayPlayer.prototype.getSpeed = function() {
      return this.speed;
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
      console.log('moving to', target);
      return this.goToTimestamp(target);
    };

    ReplayPlayer.prototype.goToTimestamp = function(timestamp) {
      var initialSpeed;
      initialSpeed = this.speed;
      if (timestamp < this.currentReplayTime) {
        console.log('resetting');
        this.init();
        this.historyPosition = 0;
      }
      this.start(this.startTimestamp);
      if (!this.interval) {
        console.log('running the game');
        this.run();
        this.changeSpeed(initialSpeed);
      }
      console.log('going to timestamp in replay', timestamp);
      this.currentReplayTime = timestamp;
      return this.emit('moved-timestamp');
    };

    ReplayPlayer.prototype.update = function() {
      var elapsed, results;
      this.currentReplayTime += this.frequency * this.speed;
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

    ReplayPlayer.prototype.receiveEntity = function(definition) {
      var entity;
      if (this.entities[definition.id]) {
        entity = this.entities[definition.id];
      } else {
        entity = new Entity(this);
      }
      this.entities[definition.id] = entity;
      entity.update(definition);
      if (definition.id === 68) {
        if (definition.cardID === 'GAME_005') {
          this.player = entity.getController();
          this.opponent = this.player.getOpponent();
        } else {
          this.opponent = entity.getController();
          this.player = this.opponent.getOpponent();
        }
        console.log('emitting player-ready event');
        return this.emit('players-ready');
      }
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
        return this.lastBatch.addCommand([command, args]);
      } else {
        this.lastBatch = new HistoryBatch(timestamp, [command, args]);
        return this.history.push(this.lastBatch);
      }
    };

    return ReplayPlayer;

  })(EventEmitter);

  module.exports = ReplayPlayer;

}).call(this);
