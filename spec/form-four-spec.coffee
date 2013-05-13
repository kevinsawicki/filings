path = require 'path'
{FormFour} = require '../lib/filings'

describe 'Form 4 parsing', ->
  describe 'getAcquisitions()', ->
    it 'returns the price, quantity, cost, and date for all acquisitions', ->
      reportPath = path.join(__dirname, 'fixtures', 'orcl-form4-hurd.xml')
      openedReport = null
      FormFour.open reportPath, (error, report) ->
        openedReport = report
      waitsFor -> openedReport?
      runs ->
        acquired = openedReport.getAcquisitions()
        expect(acquired.length).toBe 1
        expect(acquired[0].shares).toBe 500000
        expect(acquired[0].price).toBe 24.14
        expect(acquired[0].cost).toBe 12070000
        expect(acquired[0].date).toBe 1364169600000

    describe 'when there is no acquired transaction price per share', ->
      it 'sets the price to 0', ->
        reportPath = path.join(__dirname, 'fixtures', 'aapl-form4-cook.xml')
        openedReport = null
        FormFour.open reportPath, (error, report) ->
          openedReport = report
        waitsFor -> openedReport?
        runs ->
          acquired = openedReport.getAcquisitions()
          expect(acquired.length).toBe 1
          expect(acquired[0].shares).toBe 200000
          expect(acquired[0].price).toBe 0
          expect(acquired[0].cost).toBe 0

  describe 'getDisposals()', ->
    it 'returns the price, quantity, cost, and date for all disposals', ->
      reportPath = path.join(__dirname, 'fixtures', 'orcl-form4-hurd.xml')
      openedReport = null
      FormFour.open reportPath, (error, report) ->
        openedReport = report
      waitsFor -> openedReport?
      runs ->
        acquired = openedReport.getDisposals()
        expect(acquired.length).toBe 1
        expect(acquired[0].shares).toBe 500000
        expect(acquired[0].price).toBe 31.6229
        expect(acquired[0].cost).toBe 15811450
        expect(acquired[0].date).toBe 1364169600000

  describe 'getProfit()', ->
    it 'returns the net profit of the paired acquired/disposal transactions', ->
      reportPath = path.join(__dirname, 'fixtures', 'orcl-form4-hurd.xml')
      openedReport = null
      FormFour.open reportPath, (error, report) ->
        openedReport = report
      waitsFor -> openedReport?
      runs ->
        expect(openedReport.getProfit()).toBe 3741450
