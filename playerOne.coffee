fs = require 'fs'
turns = 0
southRoverOffset = 0

latestString = ''
process.stdin.on 'data', (chunk) ->
  latestString += chunk.toString()
  fs.writeFile 'one.log', latestString + '\n\nTURN ' + turns
  if latestString[latestString.length - 1] is '\n'
    boardState = JSON.parse latestString
    for column, x in boardState
      for cell, y in column
        if cell? and cell.player.name is 'PLAYER ONE'
          if x is 0 and y isnt 0 and y < (boardState[0].length - southRoverOffset - 1)
            console.log "#{x} #{y} MOVE S"
          else if x is 0 and y isnt 0 and southRoverOffset < boardState[0].length
            southRoverOffset += 2
          else if x + 1 < boardState.length and boardState[x + 1][y]?.player?.name is 'PLAYER TWO'
            console.log "#{x} #{y} ATTACK E"
          else if y + 1 < boardState[0].length and boardState[x][y + 1]?.player?.name is 'PLAYER TWO'
            console.log "#{x} #{y} ATTACK S"
          else if y - 1 >= 0 and boardState[x][y - 1]?.player?.name is 'PLAYER TWO'
            console.log "#{x} #{y} ATTACK N"
          else if x - 1 >= 0 and boardState[x - 1][y]?.player?.name is 'PLAYER TWO'
            console.log "#{x} #{y} ATTACK W"
          else if y %% 2 is 1 and y + 1 < boardState[0].length and not boardState[x][y + 1]?
            console.log "#{x} #{y} MOVE S"
          else if y %% 2 is 1 and x + 1 < boardState.length
            console.log "#{x} #{y} MOVE E"
          else if cell.prime < 5
            console.log "#{x} #{y} PRIME"
          else if x + 1 < boardState.length and not boardState[x + 1][y]?
            console.log "#{x} #{y} SPLIT E"
          else if x - 1 >= 0 and not boardState[x - 1][y]?
            console.log "#{x} #{y} SPLIT W"
          else if y + 1 < boardState[0].length
            console.log "#{x} #{y} SPLIT S"
          else if y - 1 >= 0
            console.log "#{x} #{y} SPLIT N"
    console.log 'DONE'
    turns++
    latestString = ''
