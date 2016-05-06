express = require 'express'
request = require 'superagent'
pluralize = require 'pluralize'

# Express settings.
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
  SLACK_INCOMING_HOOK: process.env.SLACK_INCOMING_HOOK

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

  unless req.body.request.shared_secret is config.COBALT_SECRET
    console.error 'Wrong secret token.'
    res.status(500).end()
    return

  report = req.body

  project_url = report.data.attributes.url
  project_name = report.data.attributes.title

  # Title
  copy_project = "#{project_name} bounty program"

  # Fallback.
  copy_short = switch report.request.event
    when "vulnerability.new_state"
      "New vulnerability has been reported."
    when "vulnerability.valid_state"
      "A vulnerability report has been rewarded."
    else
      err = "Unknown event: #{report.request.event}"
      console.error err
      console.log "Data dump: %j", report
      err

  # Text.
  copy_full = copy_short
  pending_count = report.data.attributes['awaiting-vulnerabilities-count']
  if pending_count > 0

    copy_color = if report.request.event isnt "vulnerability.valid_state"
      "danger"
    else
      "warning"

    copy_verb = pluralize 'evaluation', pending_count
    copy_full += "\nYou have #{pending_count} pending #{copy_verb} in total."
  else
    copy_color = "good"
    copy_full += "\nNice job! You don't have any open reports!"

  # Post to Slack.
  request
  .post config.SLACK_INCOMING_HOOK
  .send
    attachments: [
      fallback: copy_short
      title: copy_project
      title_link: project_url
      color: copy_color
      text: copy_full
    ]
  .end (err, res) -> console.log err if err

  res.send 'ok'
  return

# Start server.
app.listen app.get('port'), ->
  console.log 'Cobalt to Slack adapter is running on port', app.get('port')
  return
