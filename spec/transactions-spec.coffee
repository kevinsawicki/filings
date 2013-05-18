path = require 'path'
http = require 'http'
express = require 'express'
transactions = require '../lib/transactions'

describe 'transactions', ->
  describe 'getTransaction()', ->
    server = null

    beforeEach ->
      app = express()
      app.get '/edgar', (request, response) ->
        response.sendfile path.join(__dirname, 'fixtures', 'transactions.xml')
      server =  http.createServer(app)
      server.listen(3000)

      process.env.SEC_EDGAR_URL = "http://localhost:3000/edgar"

    afterEach ->
      server.close()

    it 'calls back with an array of transactions', ->
      callback = jasmine.createSpy('callback')
      transactions.getTransactions(123, 4, callback)
      waitsFor -> callback.callCount is 1
      runs ->
        error = callback.mostRecentCall.args[0]
        expect(error).toBeNull()
        transactions = callback.mostRecentCall.args[1]
        expect(transactions.length).toBe 63
        expect(transactions[0].date.getTime()).toBe 1359988200000
        expect(transactions[0].cik).toBe 1214156
        expect(transactions[0].id).toBe 112760213004083
