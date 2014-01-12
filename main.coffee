#! ./node_modules/.bin/coffee

# imports

fs = require 'fs'
request = require 'request'
rl = require 'readline'

{format} = require 'util'
{platform} = require 'os'
{spawn} = require 'child_process'

# settings

cache = __dirname + '/history.log'

prefix = ' > '
separator = ' '

# commands

cmd =

  exit: ->
    cli.close()
    process.stdin.destroy()

  clear: ->
    console.log '\x33[2J\x33[0;0f'
    cli.prompt()

  cin: (query) ->
    if opts = /(.+?) (.+)/.exec query
      go 'http://www.google.co.uk/movies?hl=en&q=%s&near=%s', opts
    else
      go 'http://www.google.co.uk/movies?hl=en&near=%s', query

  gif: (query) ->
    go 'http://www.google.co.uk/search?hl=en&tbm=isch&tbs=itp:animated&q=%s&safe=off', query

  img: (query) ->
    go 'http://www.google.co.uk/search?hl=en&tbm=isch&q=%s&safe=off', query

  lkp: (query) ->
    go 'http://www.answers.com/%s', query

  map: (query) ->
    switch true
      when !! opts = /(.+?) -> (.+)/.exec query
        go 'http://maps.google.co.uk/maps?hl=en&saddr=%s&daddr=%s', opts
      when !! opts = /(.+?), (.+)/.exec query
        go 'http://maps.google.co.uk/maps?hl=en&q=%s&near=%s', opts
      else
        go 'http://maps.google.co.uk/maps?hl=en&q=%s', query

  mov: (query) ->
    cmd.run query + ' site:imdb.com'

  prg: (query) ->
    cmd.wki query + ' (tv series)'

  run: (query) ->
    query = encodeURIComponent(query)
    request
      followRedirect: false
      headers:
        referer: 'http://www.google.co.uk/'
      uri: "http://www.google.co.uk/search?hl=en&q=#{query}&btnI=I'm+Feeling+Lucky"
    , (err, res) ->
      if err or not res.headers?.location?
        error '404 Not Found'
      else
        go res.headers.location

  trn: ->
    go 'http://www.nationalrail.co.uk'

  url: (query) ->
    go query

  vid: (query) ->
    go 'http://www.google.co.uk/search?hl=en&tbm=vid&q=%s', query

  wki: (query) ->
    cmd.run query + ' site:en.wikipedia.org'

  www: (query) ->
    go 'http://www.google.co.uk/search?hl=en&q=%s', query

# functions

browse = (url) ->
  if platform() is 'win32'
    browser = 'rundll32.exe'
    params = ['url.dll,FileProtocolHandler', url]
  else
    browser = 'x-www-browser'
    params = [url]
  spawn(browser, params, { detached: true }).unref()

error = (message) ->
  console.log prefix.replace(/[^\s]/g, ' ') + '\x33[1;31m' + message + '\x33[m'

go = (url, parameters) ->
  if parameters
    if Array.isArray parameters
      parameters.shift()
    else
      parameters = [parameters]
    url = format.apply null, [url].concat parameters.map(encodeURIComponent)
  browse url
  cli.prompt()
  cli.resume()

history = ->
  return '' if @line.length is 0

  index = @history.indexOf @line
  if ~index
    @history.splice index, 1

  @history.unshift @line unless @line is 'exit'
  @history.pop() if @history.length > @output.rows

  @historyIndex = -1
  @history[0]

load = ->
  fs.readFile cache, 'utf-8', (err, data) ->
    if err
      error 'Unable to load history from ' + cache
    else
      cli.history = data.split '\n'

save = ->
  lines = cli.history.join '\n'
  fs.writeFileSync cache, lines, 'utf-8'

# main

process.on 'exit', save
process.on 'SIGHUP', process.exit

cli = rl.createInterface process.stdin, process.stdout

cli._addHistory = history
cli.output.rows = 8192

cli.on 'close', cmd.exit
cli.on 'line', (line) ->
  cli.pause()
  split = line.indexOf separator
  op = cmd[if ~split then line.slice 0, split else line]
  switch true
    when op && !~split
      op true
    when op && op.length is 1
      op line.slice split + separator.length
    else
      cmd.www line

cli.setPrompt prefix, prefix.length
cli.prompt()

load()
