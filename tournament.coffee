colors = require 'colors'

PRIME_THRESHOLD = 5

color = (color, char) ->
  switch color
    when 'blue' then char.blue
    when 'red' then char.red
    when 'green' then char.green
    when 'yellow' then char.yellow


class Directive
  constructor: (@base, @direcion) ->

dirMap = {
  N: x: 0, y: -1
  S: x: 0, y: 1
  E: x: 1, y: 0
  W: x: -1, y: 0
}

class Player
  constructor: (@script, @color, @name) ->
    @process = child_process.exec @script

  feed: (board) ->
    @process.stdin.write board.serialize()
    response = @process.stdout.read().toString().split '\n'
    return for line in response
      line = line.split ' '
      coord = x: Number line[0], y: Number line[1]
      new board.Action coord, new Directive line[2], dirMap[line[3]]

class Board
  constructor: (@dimensions, @players) ->
    @board = ((null for [0...@dimensions.height]) for [0...@dimensions.width])

    board = @

    # "Inner class" Amoeba
    @Amoeba =  class Amoeba
      constructor: (@pos, @player) ->
        @prime = 0
        @deleteFlag = false

      render: ->
        color @player.color, '#'

    @Action = class Action
      constructor: (@player, @coord, @directive) ->

      perform: (newBoard, amoeba) ->
        newpos = null
        if @directive.direction?
          newpos = x: amoeba.pos.x + @directive.direction.x, y: amoeba.pos.y + @directive.direction.y

        switch @directive.base
          when 'MOVE'
            if newBoard[newpos.x][newpos.y]?
              newBoard[newpos.x][newpos.y].deleteFlag = amoeba.deleteFlag = true
            else
              newBoard[newpos.x][newpos.y] = amoeba
          when 'ATTACK'
            if board.board[newpos.x][newpos.y]?
              board.board[newpos.x][newpos.y].deleteFlag = true
          when 'PRIME'
            amoeba.prime += 1
          when 'SPLIT'
            if amoeba.prime >= PRIME_THRESHOLD
              newBoard[newpos.x][newpos.y] =
                new Amoeba amoeba.player, newpos

      @board[0][0] = new Amoeba {x: 0, y: 0}, @players[0]
      @board[@dimensions.width - 1][@dimensions.height - 1] = new Amoeba {x: @dimensions.width - 1, y: @dimensions.height - 1}, @players[1]

  render: ->
    strs = ('' for [0...@dimensions.height])
    for column, x in @board
      for cell, y in column
        strs[y] += cell?.render?() ? ' '

    return strs.join '\n'

  runStep: (actions) ->
    newBoard = ((null for [0...@dimensions.height]) for [0...@dimensions.width])
    for action in actions
      if board.board[action.coord]?.player is action.player
        action.perform newBoard, board.board[action.coord]

    @board = newBoard

  serialize: -> JSON.stringify @board

  step: ->
    actions = []
    for player in @players
      actions = actions.concat player.feed @serialize()

    @runStep actions

playerOne = new Player 'coffee playerOne.coffee', 'blue', 'PLAYER ONE'
playerTwo = new Player 'coffee playerTwo.coffee', 'red', 'PLAYER TWO'

board = new Board {width: 50, height: 50}, [playerOne, playerTwo]

(tick = ->
  board.step()
  console.log board.render()
  setTimeout tick, 1000)()
