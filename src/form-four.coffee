fs = require 'fs'
{DOMParser} = require 'xmldom'
xpath = require 'xpath'

module.exports =
class FormFour
  @open: (path, callback) ->
    fs.readFile path, {encoding: 'utf8'}, (error, data) ->
      if error?
        callback(error)
      else
        callback(null, new FormFour(data))

  constructor: (@contents) ->
    @document = new DOMParser().parseFromString(@contents)

  getTransaction: (transactionNode) ->
    date = Date.parse(xpath.select('transactionDate/value/text()', transactionNode).toString())
    return null if isNaN(date)

    shares = parseInt(xpath.select('transactionAmounts/transactionShares/value/text()', transactionNode).toString())
    return null if isNaN(shares)

    price = parseFloat(xpath.select('transactionAmounts/transactionPricePerShare/value/text()', transactionNode).toString())
    return null if isNaN(price)

    cost = shares * price
    {date, shares, price, cost}

  getAcquisitions: ->
    acquisitions = []
    transactions = xpath.select('//nonDerivativeTransaction', @document)
    for transaction in transactions
      continue unless xpath.select('transactionAmounts/transactionAcquiredDisposedCode/value/text()', transaction).toString() is 'A'
      acquisition = @getTransaction(transaction)
      acquisitions.push(acquisition) if acquisition?

    acquisitions

  getDisposals: ->
    disposals = []
    transactions = xpath.select('//nonDerivativeTransaction', @document)
    for transaction in transactions
      continue unless xpath.select('transactionAmounts/transactionAcquiredDisposedCode/value/text()', transaction).toString() is 'D'
      disposal = @getTransaction(transaction)
      disposals.push(disposal) if disposal?

    disposals

  getProfit: ->
    acquiredShares = 0
    acquiredCost = 0
    for {shares, cost} in @getAcquisitions()
      acquiredShares += shares
      acquiredCost += cost

    disposedShares = 0
    disposedCost = 0
    for {shares, cost} in @getDisposals()
      disposedShares += shares
      disposedCost += cost

    if acquiredShares is disposedShares
      disposedCost - acquiredCost
    else
      0
