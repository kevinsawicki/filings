{DOMParser} = require 'xmldom'
xpath = require 'xpath'
request = require 'request'

module.exports =
  fetch: (cik, type, callback) ->
    baseUrl = process.env.SEC_EDGAR_URL ? 'http://www.sec.gov/cgi-bin/browse-edgar'
    url = "#{baseUrl}?action=getcompany&output=atom&start=0&count=1000&CIK=#{cik}&type=#{type}"
    url = "#{url}&owner=only"if parseInt(type) is 4

    request url, (error, response, body) ->
      if error?
        callback(error)
      else
        dom = new DOMParser().parseFromString(body)
        cik = parseInt(xpath.select('/feed/company-info/cik/text()', dom))
        transactions = []
        for transaction in xpath.select('//entry/content', dom)
          filingDate = xpath.select('filing-date/text()', transaction).toString()
          date = new Date("#{filingDate} 14:30:00 GMT")
          accessionNumber = xpath.select('accession-nunber/text()', transaction).toString()
          id = accessionNumber.replace(/-/g, '')
          type = xpath.select('filing-type/text()', transaction).toString()
          transactions.push({date, cik, id, type})
        callback(null, transactions)
