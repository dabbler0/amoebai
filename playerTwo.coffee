fs = require 'fs'
turns = 0

latestString = ''
process.stdin.on 'data', (chunk) ->
  latestString += chunk.toString()
  fs.writeFile 'two.log', latestString + '\n\nTURN ' + turns
  if latestString[latestString.length - 1] is '\n'
    boardState = JSON.parse latestString
    for column, x in boardState
      for cell, y in column
        if cell? and cell.player.name is 'PLAYER TWO'
          if cell.prime < 5
            console.log "#{x} #{y} PRIME"
          else if not boardState[x - 1][y]?
            console.log "#{x} #{y} SPLIT W"
          else if not boardState[x][y - 1]?
            console.log "#{x} #{y} SPLIT N"

    console.log 'DONE'
    turns++
    latestString = ''
