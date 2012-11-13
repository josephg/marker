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

users = do ->
  try
    str = fs.readFileSync "users.json", 'utf-8'
    JSON.parse str
  catch e
    {}

app.get '/', (req, res) ->
  u = (users[req.user] ?= {})
  res.render 'index', user:req.user, data:u

app.get '/dashboard', (req, res) ->
  res.render 'dashboard', users:users

testArgs =
  4: ['4', '10']
  5: [9, 13, -1, -10]

input =
  1: "3 2\n"
  2: "2\nasdf\nasdf\n"
  3: "100 1000 110 1000\n"

expectedOutput =
  1: "+++\n+++"
  2: "The average of 1 2 3 should be 2... ✓"
  3: "105.00 1008.66"
  5: "9 + 13 + -1 = 21"

additionalCFlags =
  2: "../../q/2.c"

saveData = ->
  fs.writeFile "users.json", JSON.stringify(users)

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
  u = (users[req.user] ?= {})
  res.render 'q', num:num, user:req.user, data:u, name:f.name, id:id, (err, str) ->
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
        # -xc++
        args = ['-Wall', '-Werror', '-g', '-lm', '-o', 'output', f.name]
        compiler = if f.name.match /\.cpp$/
          args.push '-std=c++11'
          args.push '-Wno-c++11-extensions'
          'clang++'
        else
          'clang'
        args.push additionalCFlags[num] if additionalCFlags[num]
        res.write "Compiling...\n"
        res.write "% #{compiler} #{args.join ' '}\n"
        cp = childprocess.spawn compiler, args, cwd:dir
        cp.stdout.on 'data', (data) -> res.write data.toString()
        cp.stderr.on 'data', (data) -> res.write data.toString()
        cp.on 'exit', (code) ->
          if code isnt 0
            res.end()
            return
          res.write "</pre><br><pre>"
          res.write "\nCompilation successful. Running smoke test...\n"
          res.write "(Input: '#{input[num]}')\n\n" if input[num]
          res.write "% ./output #{testArgs[num]?.join(' ') or ''}\n"
          cp = childprocess.spawn './output', testArgs[num] or [], cwd:dir
          cp.stdin.end input[num] if input[num]
          
          timeout = setTimeout ->
              cp.kill 'SIGKILL'
              res.write "\nYour program was too slow. I think it had locked up. Killed the bitch.\n"
            , 5000

          out = []
          cp.stdout.on 'data', (data) ->
            res.write data.toString()
            out.push data.toString()
            if out.length > 100
              cp.kill 'SIGKILL'
              res.write "\nUgh so spammy. Killed.\n"
          cp.stderr.on 'data', (data) -> res.write data.toString()
          cp.on 'exit', (code) ->
            res.write "\nExit code: #{code}\n</pre>"
            clearTimeout timeout

            expected = expectedOutput[num]?.trim()
            fail = null
            
            if code == null
              fail = 'Program crashed'
            else if expected and out.join('')?.trim() isnt expected
              fail = "Expected: <code>#{expected}</code>"

            if fail == null
              res.write "<h1>Test passed - Submission accepted!</h1>"
              res.write """
<p>Super simple tests passed. But you should run your own tests as well, just in case.
I'm going to be running more tests when I mark for reals.</p>"""

            else
              res.write "<br><h1>FAIL!</h1>"
              res.write "<p>You can F5 (refresh) & yes to 'Resubmit form data' to resubmit</p>"
              res.write fail

            u[num] =
              status:if fail == null then 'Passed' else 'Fails tests'
              time:(new Date()).toString()
              id:id
            saveData()

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
