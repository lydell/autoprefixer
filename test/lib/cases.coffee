fs        = require('fs')
parse     = require('css-parse')
stringify = require('sheet')

module.exports =
  read: (file) ->
    fs.readFileSync("#{__dirname}/../cases/#{file}.css").toString()

  load: (file) ->
    parse(@read(file))

  clean: (string) ->
    string.trim().replace(/\s+/g, ' ').replace(/\/\*.*?\*\/\ /g, '')

  compare: (nodes, file) ->
    ideal = @clean @read(file)
    real  = @clean stringify(nodes).css
    real.should.eql(ideal)
