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
utils = window.ig.utils
window.ig.Pekacek = class Pekacek
  kostSide: 28px
  (parentElement, @downloadCache) ->
    @obvody_meta = window.ig.senat_obvody_meta
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
    kostInCol = 3
    stranyZiskyAssoc = {}
    for obvod in @contestedObvody
      zkratka = if senatStrany[obvod.new.data.zkratka] then obvod.new.data.zkratka else "NEZ"
      stranyZiskyAssoc[zkratka] ?= []
      stranyZiskyAssoc[zkratka].push obvod
    stranyZisky = for zkratka, obvody of stranyZiskyAssoc
      {zkratka, zisk: obvody.length, obvody}
    stranyZisky.sort (a, b) ->
      | a.zkratka == "NEZ" => 1
      | b.zkratka == "NEZ" => -1
      | _ => b.zisk - a.zisk
    stranyZiskyIndices = {}
    for {zkratka, obvody}:strana, index in stranyZisky
      strana.index = index
      stranyZiskyIndices[zkratka] = index
      obvody.sort (a, b) ->
        dA = a.new.hlasu - a.new2.hlasu
        dB = b.new.hlasu - b.new2.hlasu
        dB - dA
      for obvod, index in obvody
        obvod.colStrana = strana
        obvod.index = index

    @strany = @kosti.selectAll \.strana .data stranyZisky, (.zkratka)
      ..enter!.append \div
        ..attr \class \strana
        ..append \div
          ..attr \class \popisek
          ..html (.zkratka)
      ..exit!remove!
      ..style \left ~> "#{(kostInCol + 1) * it.index * (@kostSide + 1)}px"
    @kosti.selectAll \.kost.active .data @contestedObvody, (.obvodId)
      ..enter!append \div
        ..attr \class "kost active"
      ..exit!
        ..classed \active \no
        ..transition!
          ..delay 800
          ..remove!
      ..style \left ~>
        l = (kostInCol + 1) * it.colStrana.index * (@kostSide + 1) + 0.5 * @kostSide
        l += (it.index % kostInCol) * @kostSide
        "#{l}px"
      ..style \bottom ~>
        "#{(Math.floor it.index / kostInCol) * @kostSide}px"
      ..style \background-color ->
        it.new.data.barva || '#999'
      ..attr \data-tooltip ~>
        out = ""
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b><br>"
        if it.new
          out += [it.new, it.new2]
            .map (kandidat, i) ->
              if kandidat.data
                "#{kandidat.data.jmeno} <b>#{kandidat.data.prijmeni}</b>: <b>#{utils.percentage kandidat.hlasu / (it.new.hlasu + it.new2.hlasu)} %</b> (#{kandidat.data.zkratka}, #{kandidat.hlasu} hl.)"
              else if i == 0
                "Zatím neznámý"
            .join "<br>"
        if it.obvodId % 3
          out += "<br>#{it.old.jmeno}, #{it.old.strana}"
        else
          out += "<br>Obvod obhajuje #{it.old.jmeno}, #{it.old.strana}"
        out
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
          obvod.new2 = @data.obvody[obvodId].kandidati[1]
