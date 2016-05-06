express = require 'express'
superagent = require 'superagent'
pluralize = require 'pluralize'
humanizeDuration = require 'humanize-duration'

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
  event = report.request.event
  copy_short = switch event
    when "vulnerability.new_state"
      project_url += '/reports'
      "New vulnerability has been reported."
    when "vulnerability.valid_state"
      project_url += '/reports?sort=newest&state=rewarded'
      "A vulnerability report has been rewarded."
    else
      err = "Unknown event: #{event}"
      console.error err
      console.log "Data dump: %j", report
      err

  # Stats.
  pending_count = report.data.attributes['awaiting-vulnerabilities-count']
  art = report.data.attributes["average-response-time"] * 1000
  art_copy = humanizeDuration art,
    round: true
    units: ['d', 'h']
    delimiter: ' '

  # Color.
  copy_color = switch
    when pending_count > 0 and event isnt "vulnerability.valid_state" then "danger"
    when pending_count > 0 then "warning"
    else "good"

  # Prepare the payload.
  msg =
    attachments: [
      fallback: copy_short
      title: copy_project
      title_link: project_url
      color: copy_color
      text: copy_short
      fields: [
        {
          title: "Open #{pluralize 'report', pending_count}"
          value: pending_count
          short: true
        },
        {
          title: "Averege response time"
          value: art_copy
          short: true
        },
      ]
    ]

  # Post to Slack.
  superagent
  .post config.SLACK_INCOMING_HOOK
  .send msg
  .end (err, res) -> console.log err if err

  # Debug:
  # console.log JSON.stringify(msg, null, 2);

  res.send 'ok'
  return

# Start server.
app.listen app.get('port'), ->
  console.log 'Cobalt to Slack adapter is running on port', app.get('port')
  return
