dates = require '../lib/dates'

describe 'date parsing', ->
  describe 'getYear(date)', ->
    it 'returns the year as an integer', ->
      expect(dates.getYear()).toBe -1
      expect(dates.getYear(null)).toBe -1
      expect(dates.getYear('')).toBe -1
      expect(dates.getYear('not a valid date')).toBe -1

      expect(dates.getYear('D2011Q4YTD')).toBe 2011
      expect(dates.getYear('D2010Q4')).toBe 2010
      expect(dates.getYear('FROM_Jan01_2012_TO_Dec31_2012')).toBe 2012
      expect(dates.getYear('D2009')).toBe 2009
