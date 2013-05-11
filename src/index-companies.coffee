path = require 'path'
fs = require 'fs'
async = require 'async'
mkdirp = require 'mkdirp'
_ = require 'underscore'
connection = require './connection'
zlib = require 'zlib'

module.exports =
class IndexCompanies
  cacheDir: null
  indexDir: null
  companiesDir: null
  copmaniesIndex: null
  connection: null

  constructor: ->
    @cacheDir = process.env.FILINGS_DIR ? path.join(process.env.HOME, '.filings')
    @indexDir = path.join(@cacheDir, 'full-index')
    @companiesDir = path.join(@cacheDir, 'companies')
    @companiesIndex = path.join(@companiesDir, 'index.json')

  parseReportingCompanies: (quarters, reportName) ->
    companies = []
    for quarter in quarters
      for line in quarter.split('\n')
        segments = line.split('|')
        continue unless segments.length is 5
        continue if companies[segments[0]]? # Ignore companies already parsed
        continue unless segments[2] is reportName
        continue unless /^\d+$/.test(segments[0]) # CIK must be all digits

        cik = segments[0]
        companies.push
          cik: cik
          name: segments[1]
          path: "/#{segments[4][..-5].replace(/-/g, '')}"
    companies

  write: (filePath, contents, callback) ->
    mkdirp path.resolve(filePath, '..'), (error) ->
      if error?
        console.error(error)
        callback(error)
      else
        fs.writeFile filePath, contents, (error) ->
          if error?
            console.error(error)
            callback(error)
          else
            callback()

  writeGzip: (filePath, contents, callback) ->
    zlib.gzip contents, (error, data) =>
      @write(filePath, data, callback)

  readGzip: (filePath, callback) ->
    fs.readFile filePath, {encoding: 'utf8'}, (error, data) ->
      if error?
        console.error(error)
        callback(error)
      else
        callback(null, data)

  readMasterIndex: (year, quarter, callback) ->
    cachePath = path.join(@indexDir, year, "Q#{quarter}", 'master.gz')
    fs.exists cachePath, (exists) =>
      if exists
        @read cachePath, (error, data) ->
          if error?
            callback(error)
          else
            console.log "Using cached Q#{quarter} index of companies"
            callback(null, data, year, quarter)
      else
        @connection.getGzip "/edgar/full-index/#{year}/QTR#{quarter}/master.gz", (error, data) =>
          if error?
            console.error(error)
            callback(error)
          else
            @writeGzip cachePath, data, (error) ->
              if error?
                callback(error)
              else
                console.log "Downloaded Q#{quarter} index of companies"
                callback(null, data, year, quarter)

  indexCompanies: =>
    year = "#{new Date().getFullYear() - 1}"
    console.log "Indexing companies that filed a 10K in #{year}"
    quarterIndices = []

    queue = async.queue (quarter, callback) =>
      @readMasterIndex year, quarter, (error, data, year, quarter) ->
        if error
          console.error(error)
        else
          quarterIndices[quarter - 1] = data
        callback(error)

    queue.drain = =>
      @connection.close()
      quarterIndices.reverse()
      companies = @parseReportingCompanies(quarterIndices, '10-K')
      missingCompanies = []
      for company in companies
        reportPath = path.join(@companiesDir, company.cik, year, '10-K.xml')
        missingCompanies.push(company) unless fs.existsSync(reportPath)
      console.log "Downloading #{missingCompanies.length} company ticker symbols"

      symbolsDownloaded = 0
      connection.pool 5, (connections) =>
        tickerQueue = async.queue (company, callback) =>
          connection = connections.pop()
          connection.list company.path, (error, files=[]) =>
            console.error(error) if error?
            for file in files
              if match = file?.name.match(/^([a-zA-Z]+)-\d+\.xml$/)
                reportName = match[0]
                company.symbol = match[1]
                break

            if reportName
              connection.getString "#{company.path}/#{reportName}", (error, data) =>
                if error?
                  console.error(error)
                  connections.push(connection)
                  callback()
                else
                  reportPath = path.join(@companiesDir, company.cik, year, '10-K.xml')
                  @write reportPath, data, (error) ->
                    symbolsDownloaded++
                    process.stdout.write("\r#{symbolsDownloaded}/#{missingCompanies.length}")
                    connections.push(connection)
                    callback()
            else
              connections.push(connection)
              callback()

        tickerQueue.concurrency = connections.length
        tickerQueue.drain = =>
          connection.close() for connection in connections
          @write(@companiesIndex, JSON.toString(companies))

        tickerQueue.push(company) for company in missingCompanies

    queue.push(quarter) for quarter in [1..4]

  run: ->
    @connection = connection.open(@indexCompanies)
