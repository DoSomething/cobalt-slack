# Expres settings.
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
    res.status(500).send('No data in payload.')
    return

  unless req.body.request?.shared_secret?
    res.status(500).send('No request payload.')
    return

  unless req.body.request.shared_secret == config.COBALT_SECRET
    res.status(500).send('Wrong secret token.')
    return

  # Log body.
  # data = req.body.data
  console.log "Data recieved:"
  console.log req.body

  res.send '200, Duh!'
  return

# Start server.
app.listen app.get('port'), ->
  console.log 'Node app is running on port', app.get('port')
  return
