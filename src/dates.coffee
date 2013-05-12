module.exports =
  getYear: (date='') ->
    return -1 unless date

    if match = date.match(/^from_([a-z]+\d{2})_(\d{4})_to_([a-z]+\d{2})_(\d{4})$/i)
      fromDate = Date.parse("#{match[1]} #{match[2]}")
      unless isNaN(fromDate)
        toDate = Date.parse("#{match[3]} #{match[4]}")
        unless isNaN(toDate)
          day = 24 * 60 * 60 * 1000
          days = (toDate - fromDate) / day
          return new Date(toDate).getFullYear() if 360 < days < 370

    if match = date.match(/^d(\d{4})$/i)
      year = parseInt(match[1])
      return year unless isNaN(year)

    if match = date.match(/^d(\d{4})q4(ytd)?$/i)
      year = parseInt(match[1])
      return year unless isNaN(year)

    -1
