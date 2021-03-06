# Description:
#   A script that tracks your outgoing pings on Slack.
#
# Commands:
#   @ping @mention [@mention ...] [message] - create a new ping
#   @ping log - view your outgoing pings
#   @ping n [n ...] - re-ping an old ping by index
#   @ping close n [n ...] - close pings by index
#   @ping help - display available commands
#
# Author:
#   Raymond Xu

class PingEntry
  constructor: (@msg, @timestamp, @channel) ->

  toString: ->
    return @msg + " [" + @timestamp + "]"

getCurrentDatetime = () ->
  currentDate = new Date()
  datetime = (currentDate.getMonth() + 1) + "/" \
    + currentDate.getDate() + "/" \
    + currentDate.getFullYear() + " " \
    + currentDate.getHours() + ":" \
    + currentDate.getMinutes() + ":" \
    + currentDate.getSeconds()
  return datetime

module.exports = (robot) ->
  # @ping @mention [@mention ...] [message] - create a new ping
  robot.hear /@ping (@.+)/i, (res) ->
    pingEntry = new PingEntry res.message.text, getCurrentDatetime(), res.message.room
    sender = "@" + res.message.user.name
    pingLog = robot.brain.get(sender)
    if not pingLog
      pingLog = []
    pingLog.push(pingEntry)
    robot.brain.set sender, pingLog

  # @ping log - view your outgoing pings
  robot.hear /@ping log\b/i, (res) ->
    sender = "@" + res.message.user.name
    pingLog = robot.brain.get(sender)
    if pingLog and pingLog.length > 0
      pingLogString = ""
      pingLog.sort (a, b) -> return a.timestamp > b.timestamp
      for i, log of pingLog
        pingLogString += "(" + i + ") " + log.toString() + "\n"
      robot.messageRoom sender, pingLogString

  # @ping n [n ...] - re-ping an old ping by index
  robot.hear /@ping (\d+)(( \d*)*)/i, (res) ->
    # Parse the message for the ping entries to re-ping
    words = res.match[0].split(" ")
    pingIndices = []
    for i, word of words
      if i >= 1 and word
        pingIndices.push(word)

    # Re-ping and bump timestamp
    sender = "@" + res.message.user.name
    pingLog = robot.brain.get(sender)
    for i, pingEntry of pingLog
      if i in pingIndices
        robot.messageRoom pingEntry.channel, pingEntry.msg
        pingEntry.timestamp = getCurrentDatetime()
    robot.brain.set sender, pingLog

  # @ping close n [n ...] - close pings by index
  robot.hear /@ping close (\d+)(( \d*)*)/i, (res) ->
    # Parse the message for the ping entries to close
    words = res.match[0].split(" ")
    closeIndices = []
    for i, word of words
      if i >= 2 and word
        closeIndices.push(word)

    # Remove the ping entries from the sender's log
    sender = "@" + res.message.user.name
    pingLog = robot.brain.get(sender)
    newPingLog = (pingEntry for i, pingEntry of pingLog when i not in closeIndices)
    robot.brain.set sender, newPingLog
