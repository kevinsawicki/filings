names = require '../lib/names'

describe 'names', ->
  describe '.normalize()', ->
    it 'normalizes names', ->
      expect(names.normalize('HURD MARK V')).toBe 'Mark V. Hurd'
