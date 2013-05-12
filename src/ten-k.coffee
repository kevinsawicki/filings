archive = require 'ls-archive'
{DOMParser} = require 'xmldom'
xpath = require 'xpath'

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

  getYear: (dateRange='') ->
    if match = dateRange.match(/^from_([a-z]+\d{2})_(\d{4})_to_([a-z]+\d{2})_(\d{4})$/i)
      fromDate = Date.parse("#{match[1]} #{match[2]}")
      return -1 if isNaN(fromDate)
      toDate = Date.parse("#{match[3]} #{match[4]}")
      return -1 if isNaN(toDate)
      day = 24 * 60 *(1000 * 60)
      days = (toDate - fromDate) / day
      return new Date(toDate).getFullYear() if 300 < days < 400
    else if match = dateRange.match(/^d(\d{4})$/i)
      year = parseInt(match[1])
      return year unless isNaN(year)
    -1

  getProfit: (year) ->
    nodes = xpath.select("//*[local-name() = 'NetIncomeLoss']", @document)
    if nodes.length is 0
      nodes = xpath.select("//*[local-name() = 'NetIncomeLossAvailableToCommonStockholdersBasic']", @document)
    netIncomeLoss = 0
    for node in nodes
      continue unless node.prefix is 'us-gaap'
      nodeYear = @getYear(xpath.select("@contextRef", node)[0]?.value)
      nodeNetIncomeLoss = parseFloat(node.firstChild.data)
      continue if isNaN(nodeNetIncomeLoss)
      netIncomeLoss += nodeNetIncomeLoss if year is nodeYear
    netIncomeLoss
