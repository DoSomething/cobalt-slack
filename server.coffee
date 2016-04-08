# Express settings.
express = require('express')
app = express()
app.set 'port', process.env.PORT or 3000

# Body parser middleware
bodyParser = require('body-parser')
multer = require('multer')
upload = multer()
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)

# Configuration
config =
  COBALT_SECRET: process.env.COBALT_SECRET

# GET /
app.get '/', (req, res) ->
  res.send 'Hello World!'
  return

# POST /
app.post '/', (req, res) ->
  # Validate input.
  unless req.body?.data?
    console.error 'No data in payload.'
    res.status(500).end()
    return

  unless req.body.request?.shared_secret?
    console.error 'No request payload.'
    res.status(500).end()
    return

  unless req.body.request.shared_secret == config.COBALT_SECRET
    console.error 'Wrong secret token.'
    res.status(500).end()
    return

  # Log body.
  console.log "Data received: %j", req.body

  # data = req.body.data
  res.send '200, Duh!'
  return

# Start server.
app.listen app.get('port'), ->
  console.log 'Cobalt to Slack adapter is running on port', app.get('port')
  return
