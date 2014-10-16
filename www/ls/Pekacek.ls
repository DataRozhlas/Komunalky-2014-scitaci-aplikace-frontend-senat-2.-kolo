senatStrany =
  "KSČM"     : zkratka: "KSČM"    color: \#e3001a
  "ČSSD"     : zkratka: "ČSSD"    color: \#FEA201
  "SZ"       : zkratka: "SZ"      color: \#0FB103
  "ANO 2011" : zkratka: "ANO"     color: \#5434A3
  "KDU-ČSL"  : zkratka: "KDU-ČSL" color: \#FEE300
  "ODS"      : zkratka: "ODS"     color: \#1C76F0
  "TOP 09"   : zkratka: "TOP"     color: \#7c0042
  "NEZ"      : zkratka: "NEZ"     color: \#999
lf = String.fromCharCode 13

window.ig.Pekacek = class Pekacek
  (parentElement, @downloadCache) ->
    @element = parentElement.append \div
      ..attr \class \pekacek
    @element.append \h2
      ..html "Získané mandáty"
    @displayed = "mandates"
    @cacheItem = @downloadCache.getItem "senat"
    (err, data) <~ @cacheItem.get
    @cacheItem.on \downloaded (data) ~>
      @resyncData data
      @redraw!
    @resyncData data
    @init!
    @redraw!

  redraw: ->
    switch
      | @displayed == "mandates" => @redrawMandates!
      | otherwise => @redrawLossess!


  redrawMandates: ->
    @kosti.selectAll \.kost.active .data @contestedObvody, (.obvodId)
      ..enter!append \div
        ..attr \class "kost active"
      ..exit!
        ..classed \active \no
        ..transition!
          ..delay 800
          ..remove!
      ..style \background-color ->
        it.new.data.barva || '#999'
    # @kosti.selectAll \.kost.active

  redrawLossess: ->

  init: ->
    @kosti = @element.append \div
      ..attr \class \kosti

  resyncData: (data) ->
    @data = data
    if @contestedObvody
      for obvodId, datum of @data.obvody
        @contestedObvodyAssoc[obvodId].new = datum
    else
      @contestedObvody      ?= []
      @contestedObvodyAssoc ?= {}
      for line in window.ig.data.old_senat.split "\n"
        [obvodId, jmeno, strana] = line.split "\t"
        obvodId = parseInt obvodId, 10
        continue unless obvodId
        strana .= replace lf, ''
        barva = senatStrany[strana]?color
        if @data.obvody[obvodId] isnt void
          obvod = if @contestedObvodyAssoc[obvodId]
            that
          else
            d =
              old: {jmeno, strana, barva}
              obvodId: obvodId
            @contestedObvodyAssoc[obvodId] = d
            @contestedObvody.push d
            d
          obvod.new = @data.obvody[obvodId].kandidati[0]
