path = require 'path'
fs = require 'fs'
async = require 'async'
_ = require 'underscore'
CSON = require 'season'
{Connection, Companies} = require './filings'

simplifyCompanyName = (name) ->
  name.toLowerCase().replace(/[,.]|( inc(orporated)?)|( corp(oration)?)/gi, '').trim()

parseSymbolLine = (line) ->
  segments = line.split('"')
  segments = _.reject segments, (segment) ->
    segment = segment.trim()
    not segment or segment is ',' or segment is '"'
  symbol = segments[0]?.trim()
  return unless symbol
  return if symbol.indexOf('/') isnt -1
  return if symbol.indexOf('^') isnt -1
  name = segments[1]?.trim()
  cap = parseFloat(segments[3]) or -1
  return {name, symbol, cap} if name

buildSymbolIndex = (callback) ->
  indexCompanies = []
  queue = async.queue (name, callback) ->
    indexPath = path.resolve(__dirname, '..', "#{name}.csv")
    fs.readFile indexPath, 'utf8', (error, contents) ->
      if error?
        console.error(error)
        callback(error)
      else
        lines = contents.split('\n')
        lines.shift() # First line contains information about fields
        for line in lines
          company = parseSymbolLine(line)
          indexCompanies.push(company) if company
        callback()

  queue.push('amex')
  queue.push('nasdaq')
  queue.push('nyse')
  queue.drain = -> callback(indexCompanies)

Connection.open (connection) ->
  Companies.fetch connection, (error, companies) ->
    connection.close()
    if error?
      console.error(error)
    else
      companies = _.uniq companies, (company) -> company.cik
      buildSymbolIndex (indexCompanies) ->
        companiesWithSymbols = []
        for company in companies
          for indexCompany in indexCompanies
            companyName = simplifyCompanyName(company.name)
            indexCompanyName = simplifyCompanyName(indexCompany.name)
            if companyName is indexCompanyName
              company.symbol = indexCompany.symbol
              company.cap = indexCompany.cap
              companiesWithSymbols.push(company)

        console.log 'Companies that filed a 10-K:', companies.length
        console.log 'Companies on the NASDAQ, NYSE, and AMEX:', indexCompanies.length
        console.log 'Companies matched to their symbol:', companiesWithSymbols.length
        companiesWithSymbols.sort (company1, company2) ->
          return -1 if company1.symbol < company2.symbol
          return 1 if company1.symbol > company2.symbol
          0
        CSON.writeFile(path.join(process.cwd(), 'companies.json'), companiesWithSymbols)
