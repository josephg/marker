express = require 'express'
fs = require 'fs'
path = require 'path'
childprocess = require 'child_process'

app = express()

app.set 'views', 'views'
app.set 'view engine', 'jade'

app.use express.logger('dev')
#app.use express.cookieParser 'super secret'
#app.use express.session()

app.use express.basicAuth (user, pass) ->
  typeof user is 'string' and user.length > 3 and user.match(/^[a-zA-Z\.0-9_]+$/)
app.engine 'jade', require('jade').__express
app.use express.static(__dirname + '/public')
app.use express.multipart uploadDir:'uploads'

log = do ->
  f = fs.createWriteStream 'log.txt', flags:'a'

  (str) ->
    f.write "#{(new Date()).toGMTString()} - #{str}\n"

log 'Server started'

app.get '/', (req, res) ->
  res.render 'index', user:req.user

testArgs =
  1: ["6"]

input =
  2: "2\nasdf\nasdf\n"

expectedOutput =
  1: "true"
  2: """Enter n: Start entering strings
    1 different strings seen."""
  4: """Testing 6 4 3 converges
Testing 1 2 4 does not converge"""

additionalCFlags =
  4: "../../q/4.c"

app.post '/q/:num', (req, res, next) ->
  unless req.files?.q and req.files.q.size > 0
    res.redirect '/'
    return

  f = req.files.q
  num = req.param 'num'
  
  log "Got file '#{f.name}' from #{req.user} for #{num} saved to #{f.path}"

  #console.log req.files

  closed = false
  res.on 'close', -> closed = true

  res.setHeader 'Content-Type', 'text/html; charset=UTF-8'

  id = path.basename f.path
  res.render 'q', num:num, user:req.user, name:f.name, id:id, (err, str) ->
    res.write str
    res.write "<pre>"

    try
      # First copy the submission to a backup place
      sdir = "submissions/#{req.user}"
      try
        fs.mkdirSync sdir
      childprocess.spawn 'cp', [f.path, "#{sdir}/q#{num}.cpp"]

      dir = "temp/#{id}"
      fs.mkdirSync dir

      cp = childprocess.spawn 'cp', [f.path, "#{dir}/#{f.name}"]
      cp.on 'exit', ->
        args = ['-xc++', '-Wall', '-Werror', '-o', 'output', '-g', f.name]
        args.push additionalCFlags[num] if additionalCFlags[num]
        res.write "Compiling...\n"
        res.write "% clang #{args.join ' '}\n"
        cp = childprocess.spawn 'clang', args, cwd:dir
        cp.stdout.on 'data', (data) -> res.write data.toString()
        cp.stderr.on 'data', (data) -> res.write data.toString()
        cp.on 'exit', (code) ->
          return unless code is 0
          res.write "\nCompilation successful. Running smoke test...\n"
          res.write "(Input: '#{input[num]}')\n\n" if input[num]
          res.write "% ./output #{testArgs[num]?.join(' ') or ''}\n"
          cp = childprocess.spawn './output', testArgs[num] or [], cwd:dir
          cp.stdin.end input[num] if input[num]
          
          timeout = setTimeout ->
              cp.kill()
              res.write "\nYour program was too slow. I think it had locked up. Killed the bitch.\n"
            , 5000

          out = []
          cp.stdout.on 'data', (data) ->
            res.write data.toString()
            out.push data.toString()
            if out.length > 100
              cp.kill()
              res.write "\nUgh so spammy. Killed.\n"
          cp.stderr.on 'data', (data) -> res.write data.toString()
          cp.on 'exit', (code) ->
            res.write "\nExit code: #{code}\n</pre>"
            clearTimeout timeout

            expected = expectedOutput[num]?.trim()
            if code != null and out.length and (!expected or out.join('').trim() is expected)
              res.write "<h1>Boring Test passed - Submission accepted!</h1>"
              res.write """
<p>Super simple tests passed. But you should run your own tests as well, just in case.
I'm going to be running more tests when I mark for reals.</p>"""
            else
              res.write "<br><h1>FAIL!</h1>"
              res.write "Expected: <pre>#{expected}</pre>" if expected
            res.end()

    catch e
      console.log e.stack
    
    return



###
    d = ->
      unless closed
        #res.write "<script>console.log('<p>hi</p>\n');</script>\n"
        res.write "asdf\n"
        setTimeout d, 1000

    d()
###

app.listen 3000
console.log 'http://localhost:3000'
