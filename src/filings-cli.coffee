fs = require 'fs'
path = require 'path'
optimist = require 'optimist'
{FormFour} = require './filings'

parseOptions = (args=[]) ->
  options = optimist(args)
  options.usage('Usage: filings <command>')
  options.alias('h', 'help').describe('h', 'Print this usage message')
  options.alias('v', 'version').describe('v', 'Print the filings version')
  options

module.exports =
  run: (args=process.argv[2..]) ->
    options = parseOptions(args)
    [command, commandArgs...] = options.argv._
    if options.argv.v
      console.log JSON.parse(fs.readFileSync('package.json')).version
    else if options.argv.h
      options.showHelp()
    else if command = options.argv._.shift()
      switch command
        when 'profit'
          reportPath = path.resolve(commandArgs.shift())
          FormFour.open reportPath, (error, formFour) ->
            if error?
              console.error(error)
            else
              console.log(formFour.getProfit())
        else
          console.error "Unrecognized command: #{command}"
    else
      options.showHelp()
