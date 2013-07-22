{DOMParser} = require 'xmldom'
xpath = require 'xpath'
request = require 'request'

module.exports =
  getAddress: (company, callback) ->
    url = "http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&output=atom&start=0&count=1&CIK=#{company}"

    request url, (error, response, body) ->
      if error?
        callback(error)
      else
        dom = new DOMParser().parseFromString(body)
        [address] = xpath.select('/feed/company-info/addresses/address[@type=\'business\']', dom)
        street1 = xpath.select('street1/text()', address).toString()
        street2 = xpath.select('street2/text()', address).toString()
        city = xpath.select('city/text()', address).toString()
        state = xpath.select('state/text()', address).toString()
        zip = xpath.select('zip/text()', address).toString()
        callback(null, {street1, street2, city, state, zip})
