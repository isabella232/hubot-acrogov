# Description:
#   checks an acronym against a set of acronyms used at CFPB and provides its meaning
#
# Dependencies:
#   local json file "acro.json"
#
# Commands:
#   hubot define <term> - returns an acronym's meaning if it's in acro.json
#   hubot define <term> as <definition> - stores acronym definition in hubot's brain
#
# Author:
#   higs4281

fs = require 'fs'

class AcroBot
  constructor: (@robot) ->
    @cache = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.acrogov
        @cache = @robot.brain.data.acrogov
      @loadPublicAcronyms()
      @loadPrivateAcronyms()
  loadPublicAcronyms: () ->
    # read the acro.json file
    acroPath = __dirname + '/acro.json'
    publicAcronyms = JSON.parse fs.readFileSync(acroPath, 'utf8')
    Object.assign @cache, publicAcronyms
  loadPrivateAcronyms: () ->
    # read an optional private acro.json file
    acroPath = __dirname + '/acro.priv.json'
    try 
      if fs.accessSync(acroPath, fs.F_OK)
        privateAcronyms = JSON.parse fs.readFileSync(acroPath, 'utf8')
        Object.assign @cache, privateAcronyms
    catch e
  addAcronym: (term, definition) ->
    @cache[term.toUpperCase()] = {
      name: definition
    }
    @robot.brain.data.acrogov = @cache
  removeAcronym: (term) ->
    delete @cache[term.toUpperCase()]
    @robot.brain.data.acrogov = @cache

  getAll: -> @cache
  buildAnswer: (term) ->
    terms = @cache
    acroObj = terms[term]
    answer = "#{term} stands for #{acroObj.name}"
    # if acroObj.note
    #   answer = answer + " — " + acroObj.note
    # if acroObj.link
    #   answer = answer + " – " + acroObj.link
    return answer

module.exports = (robot) ->
  acroBot = new AcroBot robot

  # get an acronym from the brain
  robot.respond /define (\w*)$/i, (res) ->
    rawTerm = res.match[1]
    term = rawTerm.toUpperCase()
    if term of acroBot.getAll()
      res.send acroBot.buildAnswer(term) 
    else
      res.send "Sorry, can't find #{rawTerm}"

  # insert an acronym into the brain
  robot.respond /define (\w*) as (.*)$/i, (res) ->
    console.log res.match
    acroBot.addAcronym(res.match[1], res.match[2])
    res.send "I added #{res.match[1]}."

  # delete an acronym from the brain
  robot.respond /stop defining (\w*)$/i, (res) ->
    rawTerm = res.match[1]
    term = rawTerm.toUpperCase()
    if term of acroBot.getAll()
      acroBot.removeAcronym(res.match[1])
      res.send "I removed #{rawTerm}."
    else
      res.send "Sorry, couldn't find #{rawTerm}"



