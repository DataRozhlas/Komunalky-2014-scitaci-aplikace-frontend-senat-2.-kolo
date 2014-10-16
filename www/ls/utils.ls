ig.utils = utils = {}


utils.offset = (element, side) ->
  top = 0
  left = 0
  do
    top += element.offsetTop
    left += element.offsetLeft
  while element = element.offsetParent
  {top, left}


utils.deminifyData = (minified) ->
  out = for row in minified.data
    row_out = {}
    for column, index in minified.columns
      row_out[column] = row[index]
    for column, indices of minified.indices
      row_out[column] = indices[row_out[column]]
    row_out
  out


utils.formatNumber = (input, decimalPoints = 0) ->
  input = parseFloat input
  if decimalPoints
    wholePart = Math.floor input
    decimalPart = input % 1
    wholePart = insertThousandSeparator wholePart
    decimalPart = Math.round decimalPart * Math.pow 10, decimalPoints
    decimalPart = decimalPart.toString()
    while decimalPart.length < decimalPoints
      decimalPart = "0" + decimalPart
    if decimalPart.length > decimalPoints
      decimalPart .= substr 0, decimalPoints
    "#{wholePart},#{decimalPart}"
  else
    wholePart = Math.round input
    insertThousandSeparator wholePart


insertThousandSeparator = (input, separator = ' ') ->
    price = Math.round(input).toString()
    out = []
    len = price.length
    for i in [0 til len]
      out.unshift price[len - i - 1]
      isLast = i is len - 1
      isThirdNumeral = 2 is i % 3
      if isThirdNumeral and not isLast
        out.unshift separator
    out.join ''

utils.download = (url, cb) ->
  if window.XDomainRequest
    xdr = new window.XDomainRequest!
      ..open "get" url
      ..onload = -> cb null, JSON.parse xdr.responseText
      ..onerror = -> cb it
      ..send!
  else
    d3.json url, cb

utils.supplementalMixin =
  updateSupplemental: ->
    sectenoPerc = utils.percentage @data.okrsky_spocteno / @data.okrsky_celkem
    if sectenoPerc == "100,0" and @data.okrsky_celkem != @data.okrsky_spocteno
      sectenoPerc = "99,9"
    @sectenoValue.html "#{sectenoPerc}&nbsp;%"
    @sectenoFill.style \width "#{@data.okrsky_spocteno / @data.okrsky_celkem * 100}%"
    if @data.volicu
      @ucastValue.html   "#{utils.percentage @data.volilo / @data.volicu}&nbsp;%"
      @ucastFill.style \width "#{@data.volilo / @data.volicu * 100}%"
    else
      @ucastValue.html   "&ndash;"
      @ucastFill.style \width "0%"

  drawSupplemental: ->
    @supplemental = @element.append \div
      ..attr \class \supplemental
    @secteno = @supplemental.append \div
      ..attr \class \secteno
      ..append \h3 .html "Sečteno"
      ..append \span
        ..attr \class \value
      ..append \div
        ..attr \class \progress
        ..append \div
          ..attr \class \fill
    @sectenoValue = @secteno.select "span.value"
    @sectenoFill = @secteno.select "div.fill"

    @ucast = @supplemental.append \div
      ..attr \class \ucast
      ..append \h3 .html "Účast"
      ..append \span
        ..attr \class \value
      ..append \div
        ..attr \class \progress
        ..append \div
          ..attr \class \fill
    @ucastValue = @ucast.select "span.value"
    @ucastFill = @ucast.select "div.fill"

utils.backbutton = (parent) ->
  parent.append \a
    ..attr \class \closebtn
    ..html '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" width="76" height="76" viewBox="0 0 76.00 76.00" enable-background="new 0 0 76.00 76.00" xml:space="preserve"><path fill="#000000" fill-opacity="1" stroke-width="0.2" stroke-linejoin="round" d="M 57,42L 57,34L 32.25,34L 42.25,24L 31.75,24L 17.75,38L 31.75,52L 42.25,52L 32.25,42L 57,42 Z "/></svg>'

utils.percentage = ->
  window.ig.utils.formatNumber it * 100, 1

barvaIterator = 140
barvyAssigned = {}
utils.resetStranyColors = ->
  barvyAssigned := {}
  barvaIterator := 140

utils.getStranaColor = (strana, fallback) ->
  barva = null
  id = null
  if typeof! strana is 'Object'
    if strana.id
      barva = window.ig.strany[that].barva
      id = that
    else if strana.barva
      barva = that
  else if strana
    id = that
    barva = window.ig.strany[that]?barva
  if barva
    that
  else
    if fallback
      fallback
    else
      if id and barvyAssigned[id]
        barvyAssigned[id]
      else
        barvaIterator += 40
        barvaIterator %= 220
        if barvaIterator < 100
          barvaIterator := 100
        barva = "rgb(#barvaIterator,#barvaIterator,#barvaIterator)"
        if id != null
          barvyAssigned[id] = barva
        barva
