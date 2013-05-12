archive = require 'ls-archive'
{DOMParser} = require 'xmldom'
xpath = require 'xpath'
dates = require './dates'

module.exports =
class TenK
  @open: (path, callback) ->
    archive.readGzip path, (error, data) ->
      if error?
        callback(error)
      else
        callback(null, new TenK(data))

  constructor: (@contents) ->
    @document = new DOMParser().parseFromString(@contents)

  select: (element) ->
    nodes = []
    for node in xpath.select("//*[local-name() = '#{element}']", @document)
      nodes.push(node) if node.prefix is 'us-gaap'
    nodes

  getProfit: (year) ->
    nodes = @select('NetIncomeLoss')
    if nodes.length is 0
      nodes = @select('NetIncomeLossAvailableToCommonStockholdersBasic')
    netIncomeLoss = 0
    for node in nodes
      nodeYear = dates.getYear(xpath.select("@contextRef", node)[0]?.value)
      nodeNetIncomeLoss = parseFloat(node.firstChild.data)
      continue if isNaN(nodeNetIncomeLoss)
      netIncomeLoss += nodeNetIncomeLoss if year is nodeYear
    netIncomeLoss
