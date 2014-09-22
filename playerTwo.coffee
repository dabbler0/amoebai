fs = require 'fs'
turns = 0

latestString = ''
process.stdin.on 'data', (chunk) ->
  latestString += chunk.toString()
  fs.writeFile 'two.log', latestString + '\n\nTURN ' + turns
  if latestString[latestString.length - 1] is '\n'
    boardState = JSON.parse latestString
    claimedState = ((false for k in boardState[0]) for k in boardState)
    for column, x in boardState
      for cell, y in column
        if cell? and cell.player.name is 'PLAYER TWO'
          if y - 1 >= 0 and boardState[x][y - 1]?.player?.name is 'PLAYER ONE'
            console.log "#{x} #{y} ATTACK N"
          else if x - 1 >= 0 and boardState[x - 1][y]?.player?.name is 'PLAYER ONE'
            console.log "#{x} #{y} ATTACK W"
          else if y + 1 < boardState[0].length and boardState[x][y + 1]?.player?.name is 'PLAYER ONE'
            console.log "#{x} #{y} ATTACK S"
          else if x + 1 < boardState.length and boardState[x + 1][y]?.player?.name is 'PLAYER ONE'
            console.log "#{x} #{y} ATTACK E"
          else if y - 1 >= 0 and not boardState[x][y - 1]? and not claimedState[x][y - 1] and (y %% 2 is 1 or (Math.random() > 0.5 and x %% 2 is 1))
            claimedState[x][y - 1] = true
            console.log "#{x} #{y} MOVE N"
          else if x - 1 >= 0 and not boardState[x - 1][y]? and not claimedState[x - 1][y] and (x %% 2 is 1 or (Math.random() > 0.5 and y %% 2 is 1))
            claimedState[x][y - 1] = true
            console.log "#{x} #{y} MOVE W"
          else if cell.prime < 5
            console.log "#{x} #{y} PRIME"
          else if y - 1 >= 0 and not boardState[x][y - 1]? and not claimedState[x][y - 1]
            claimedState[x][y - 1] = true
            console.log "#{x} #{y} SPLIT N"
          else if x - 1 >= 0 and not boardState[x - 1][y]? and not claimedState[x - 1][y]
            claimedState[x - 1][y] = true
            console.log "#{x} #{y} SPLIT W"

    console.log 'DONE'
    turns++
    latestString = ''
