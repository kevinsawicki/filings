Ftp = require 'ftp'
async = require 'async'
zlib = require 'zlib'

module.exports =
class Connection
  @open: (readyCallback) -> new Connection(readyCallback)

  @pool: (numberOfConnections, callback) ->
    connections = []
    connectionQueue = async.queue (number, callback) =>
      Connection.open (connection) ->
        connections.push(connection)
        callback()
    connectionQueue.push(index) for index in [1..numberOfConnections]
    connectionQueue.drain = ->
      callback(connections)

  constructor: (readyCallback) ->
    @ftp = new Ftp()
    @ftp.connect(host: 'ftp.sec.gov')
    @ftp.on 'ready', => readyCallback(this)

  readStream: (stream, callback) ->
    chunks = []
    stream.on 'error', (error) ->
      callback?(error)
      callback = null
    stream.on 'data', (chunk) ->
      chunks.push(chunk)
    stream.on 'end', ->
      callback?(null, Buffer.concat(chunks).toString())
      callback = null

  getGzip: (path, callback) ->
    @get path, (error, stream) =>
      if error?
        callback(error)
      else
        @readStream(stream.pipe(zlib.createGunzip()), callback)

  getString: (path, callback) ->
    @get path, (error, stream) =>
      if error?
        callback(error)
      else
        @readStream(stream, callback)

  get: (args...) -> @ftp.get(args...)

  list: (args...) -> @ftp.list(args...)

  close: -> @ftp.end()
