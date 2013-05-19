fs = require 'fs'
path = require 'path'
optimist = require 'optimist'
async = require 'async'
humanize = require 'humanize-plus'
{Names, Connection, Transactions, FormFour} = require './filings'

parseOptions = (args=[]) ->
  options = optimist(args)
  options.usage('Usage: flips <cik>')
  options.demand(1)
  options.alias('h', 'help').describe('h', 'Print this usage message')
  options.alias('v', 'version').describe('v', 'Print the flips version')
  options

fetchTransaction = ({connection, transaction}, callback) ->
  FormFour.fetch connection, transaction, (error, form) ->
    if error?
      console.error(error)
    else
      profit = form.getProfit()
      if profit > 0
        {date} = transaction
        month = "#{date.getMonth() + 1}"
        month = "0#{month}" if month.length is 1
        day = "#{date.getDate()}"
        day = "0#{day}" if day.length is 1
        date = "#{month}/#{day}/#{date.getFullYear()}"
        owner = form.getOwner()
        console.log date, "$#{humanize.intcomma(Math.floor(profit))} #{Names.normalize(owner.name)} #{owner.title}"
    callback()

module.exports =
  run: (args=process.argv[2..]) ->
    options = parseOptions(args)
    [cik] = options.argv._
    if options.argv.v
      console.log JSON.parse(fs.readFileSync('package.json')).version
    else if options.argv.h
      options.showHelp()
    else if cik
      Transactions.fetch cik, 4, (error, transactions) ->
        if error?
          console.error(error)
          process.exit(1)
        else
          Connection.open (connection) ->
            queue = async.queue(fetchTransaction)
            queue.drain = -> connection.close()
            queue.push({connection, transaction}) for transaction in transactions
    else
      options.showHelp()
