async = require 'async'

readMasterIndex = (connection, year, quarter, callback) ->
  connection.getGzip "/edgar/full-index/#{year}/QTR#{quarter}/master.gz", (error, data) =>
    if error?
      callback(error)
    else
      callback(null, data, year, quarter)

parseReportingCompanies = (quarters, reportName) ->
  companies = []
  for quarter in quarters
    for line in quarter.split('\n')
      segments = line.split('|')
      continue unless segments.length is 5
      continue if companies[segments[0]]? # Ignore companies already parsed
      continue unless segments[2] is reportName
      continue unless /^\d+$/.test(segments[0]) # CIK must be all digits

      cik = segments[0]
      name = segments[1].trim()
      companies.push({cik, name})
  companies

module.exports =
  fetch: (connection, callback) ->
    year = "#{new Date().getFullYear() - 1}"
    quarterIndices = []
    processQuarter = (quarter, callback) ->
      readMasterIndex connection, year, quarter, (error, data, year, quarter) ->
        if error?
          callback(error)
        else
          quarterIndices[quarter - 1] = data
          callback()

    operations = []
    [1..4].forEach (quarter) ->
      operations.push (callback) -> processQuarter(quarter, callback)
    async.waterfall operations, (error) ->
      if error?
        callback(error)
      else
        quarterIndices.reverse()
        companies = parseReportingCompanies(quarterIndices, '10-K')
        callback(null, companies)
