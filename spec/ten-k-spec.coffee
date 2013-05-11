path = require 'path'
TenK = require '../lib/ten-k'

describe '10-K', ->
  describe '.getProfit(year)', ->
    it 'returns the profit for the given year', ->
      reportPath = path.join(__dirname, 'fixtures', 'luv-2012-10-K.gz')
      openedReport = null
      TenK.open reportPath, (error, report) ->
        openedReport = report
      waitsFor -> openedReport?
      runs ->
        expect(openedReport.getProfit(2012)).toBe 421000000
        expect(openedReport.getProfit(2011)).toBe 178000000
        expect(openedReport.getProfit(2010)).toBe 459000000
