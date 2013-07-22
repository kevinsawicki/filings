{capitalizeAll} = require 'humanize-plus'

module.exports =
  normalize: (name='') ->
    name = name.toLowerCase()
    segments = name.split(' ')
    segments.push(segments.shift())
    for segment, index in segments
      segments[index] = "#{segment}." if segment.length is 1
    capitalizeAll(segments.join(' '))
