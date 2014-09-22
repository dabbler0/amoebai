colors = require 'colors'
child_process = require 'child_process'

PRIME_THRESHOLD = 5

color = (color, char) ->
  switch color
    when 'blue' then char.blue
    when 'red' then char.red
    when 'green' then char.green
    when 'yellow' then char.yellow

class Directive
  constructor: (@base, @direction) ->

dirMap = {
  N: {x: 0, y: -1}
  S: {x: 0, y: 1}
  E: {x: 1, y: 0}
  W: {x: -1, y: 0}
}

class Player
  constructor: (@script, @color, @name) ->
    @process = child_process.exec @script

  feed: (board, cb) ->
    @process.stdin.write board.serialize() + '\n\n\n\n'
    await
      cont = defer response
      str = ''
      @process.stdout.once 'data', fn = (data) =>
        str += data.toString()
        if str[-5..-1] is 'DONE\n'
          cont str
        else
          @process.stdout.once 'data', fn
    response = response.split('\n')[...-2]
    actions = []
    for line in response
      line = line.split ' '
      coord = x: Number(line[0]), y: Number(line[1])
      actions.push new board.Action @, coord, new Directive line[2], dirMap[line[3]]

    cb actions

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
        color @player.color, @prime.toString()

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
            amoeba.pos = newpos
          when 'ATTACK'
            if board.board[newpos.x][newpos.y]?
              board.board[newpos.x][newpos.y].deleteFlag = true
            newBoard[amoeba.pos.x][amoeba.pos.y] = amoeba
          when 'PRIME'
            amoeba.prime += 1
            newBoard[amoeba.pos.x][amoeba.pos.y] = amoeba
          when 'SPLIT'
            if amoeba.prime >= PRIME_THRESHOLD
              newBoard[newpos.x][newpos.y] =
                new Amoeba newpos, amoeba.player
            newBoard[amoeba.pos.x][amoeba.pos.y] = amoeba
            amoeba.prime = 0

    @board[0][0] = new Amoeba {x: 0, y: 0}, @players[0]
    @board[@dimensions.width - 1][@dimensions.height - 1] = new Amoeba {x: @dimensions.width - 1, y: @dimensions.height - 1}, @players[1]

  render: ->
    strs = ('' for [0...@dimensions.height])
    for column, x in @board
      for cell, y in column
        if cell?
          strs[y] += cell.render()
        else
          strs[y] += ' '

    return strs.join '\n'

  runStep: (actions) ->
    newBoard = ((null for [0...@dimensions.height]) for [0...@dimensions.width])
    actionsDict = {}
    for action in actions
      actionsDict[action.coord.x + ',' + action.coord.y] = action

    for column, x in @board
      for cell, y in column
        if cell? and (x + ',' + y) of actionsDict
          action = actionsDict[x + ','  + y]
          if cell.player is action.player
            action.perform newBoard, cell
        else if cell?
          newBoard[x][y] = cell

    for column, x in newBoard
      for cell, y in column
        if cell?.deleteFlag
          newBoard[x][y] = null

    @board = newBoard

  serialize: -> JSON.stringify @board, (k, v) -> if k is 'process' then null else v

  step: (cb) ->
    actions = []
    for player in @players
      await player.feed @, defer newActions
      actions = actions.concat newActions

    @runStep actions

    cb()

playerOne = new Player 'coffee playerOne.coffee', 'blue', 'PLAYER ONE'
playerTwo = new Player 'coffee playerTwo.coffee', 'red', 'PLAYER TWO'

playerOne.process.stderr.pipe process.stderr
playerTwo.process.stderr.pipe process.stderr

board = new Board {width: 25, height: 25}, [playerOne, playerTwo]
turn = 0

speed = Number process.argv[2]

(tick = ->
  board.step ->
    #console.log JSON.stringify board.board, ((k, v) -> if k is 'process' then null else v), 2
    process.stdout.write '\u001B[2J\u001B[0;0f'
    console.log 'TICK', turn
    console.log board.render()
    turn++
    setTimeout tick, speed)()
