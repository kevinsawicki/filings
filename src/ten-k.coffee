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

  getProfit: (year) ->
    nodes = xpath.select("//*[local-name() = 'NetIncomeLoss']", @document)
    if nodes.length is 0
      nodes = xpath.select("//*[local-name() = 'NetIncomeLossAvailableToCommonStockholdersBasic']", @document)
    netIncomeLoss = 0
    for node in nodes
      continue unless node.prefix is 'us-gaap'
      nodeYear = dates.getYear(xpath.select("@contextRef", node)[0]?.value)
      nodeNetIncomeLoss = parseFloat(node.firstChild.data)
      continue if isNaN(nodeNetIncomeLoss)
      netIncomeLoss += nodeNetIncomeLoss if year is nodeYear
    netIncomeLoss
