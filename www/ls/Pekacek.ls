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
  kostInCol: 3
  (parentElement, @downloadCache) ->
    @obvody_meta = window.ig.senat_obvody_meta
    @element = parentElement.append \div
      ..attr \class \pekacek
    _title = @element.append \h2
    title = _title.append \span .html "Získané mandáty"
    subtitle = _title.append \span
      ..attr \class \subtitle
      ..html "Zobrazit zisky a ztráty stran&hellip;"
      ..on \click ~>
        if @displayed == "mandates"
          @displayed = "losses"
          title.html "Zisky a ztráty stran"
          subtitle.html "Zobrazit získané mandáty&hellip;"
        else
          @displayed = "mandates"
          title.html "Získané mandáty"
          subtitle.html "Zobrazit zisky a ztráty stran&hellip;"
        @redraw!
    @drawArrows!
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
    @arrows.classed \disabled yes
    stranyZiskyAssoc = {}
    for obvod in @contestedObvody
      zkratka = if senatStrany[obvod.new.data.zkratka] then obvod.new.data.zkratka else "NEZ"
      stranyZiskyAssoc[zkratka] ?= []
      continue if obvod.new.hlasu == 0
      stranyZiskyAssoc[zkratka].push obvod
    stranyZisky = for zkratka, obvody of stranyZiskyAssoc
      {zkratka, zisk: obvody.length, obvody}
    stranyZisky.sort (a, b) ->
      | a.zkratka == "NEZ" => 1
      | b.zkratka == "NEZ" => -1
      | b.zisk - a.zisk => that
      | a.zkratka > b.zkratka => 1
      | otherwise => -1
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
    @resortStrany!
    @strany.classed \losses no
    @kosti.selectAll \.kost.active .data (@contestedObvody.filter -> it.new.hlasu)
      ..enter!append \div
        ..attr \class "kost"
        ..transition!delay 1 .attr \class "kost active"
      ..exit!
        ..classed \active no
        ..transition!
          ..delay 800
          ..remove!
      ..style \left ~>
        l = (@kostInCol + 1) * it.colStrana.index * (@kostSide + 1) + 0.5 * @kostSide
        l += (it.index % @kostInCol) * @kostSide
        "#{l}px"
      ..style \bottom ~>
        "#{(Math.floor it.index / @kostInCol) * @kostSide}px"
      ..style \background-color ->
        it.new.data.barva || '#999'
      ..on \click ~>
        window.ig.senat.highlight it.obvodId
        window.location = '#senat-obv-' + it.obvodId
      ..attr \data-tooltip ~>
        out = ""
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b><br>"
        if it.new
          out += [it.new, it.new2]
            .map (kandidat, i) ->
              if kandidat.data
                "#{kandidat.data.jmeno} <b>#{kandidat.data.prijmeni}</b>: <b>#{utils.percentage kandidat.hlasu / (it.new.hlasu + it.new2.hlasu || 1)} %</b> (#{kandidat.data.zkratka}, #{kandidat.hlasu} hl.)"
              else if i == 0
                "Zatím neznámý"
            .join "<br>"
        if it.obvodId % 3
          out += "<br>#{it.old.jmeno}, #{it.old.strana}"
        else
          out += "<br>Obvod obhajuje #{it.old.jmeno}, #{it.old.strana}"
        out

  redrawLossess: ->
    @arrows.classed \disabled no
    @element.classed \losses yes
    bilanceAssoc = {}
    bilances = for zkratka, data of senatStrany
      lossObj =
        losses: []
        gains: []
        zkratka: zkratka
        barva: data.color
      bilanceAssoc[zkratka] = lossObj
    for obvod in @contestedObvody
      continue unless obvod.new.hlasu
      newZkratka = if senatStrany[obvod.new.data.zkratka] then obvod.new.data.zkratka else "NEZ"
      oldZkratka = if senatStrany[obvod.old.strana] then obvod.old.strana else "NEZ"
      if newZkratka != oldZkratka
        atLoss = bilanceAssoc[oldZkratka]
        atGain = bilanceAssoc[newZkratka]
        if atLoss.gains.length
          atLoss.gains.pop!
        else
          atLoss.losses.push obvod
        if atGain.losses.length
          atGain.losses.pop!
        else
          atGain.gains.push obvod
    for bilance in bilances
      bilance.bilance = bilance.gains.length - bilance.losses.length
    bilances.sort (a, b) -> b.bilance - a.bilance
    bilanceKosti = []
    # bilances.length = 5
    for bilance, stranaIndex in bilances
      bilance.index = stranaIndex
      for loss, bilanceIndex in bilance.losses
        obj =
          index     : bilanceIndex
          bilance   : bilance
          direction : -1
          data      : loss
        bilanceKosti.push obj
      for gain, bilanceIndex in bilance.gains
        obj =
          index     : bilanceIndex
          bilance   : bilance
          direction : 1
          data      : gain
        bilanceKosti.push obj
    @strany = @kosti.selectAll \.strana .data bilances, (.zkratka)
    @resortStrany!
    @strany.classed \losses yes
    @kosti.selectAll \.kost.active .data bilanceKosti
      ..enter!append \div
        ..attr \class "kost"
        ..transition!delay 1 .attr \class "kost active"
      ..exit!
        ..classed \active no
        ..transition!
          ..delay 800
          ..remove!
      ..style \left ~>
        l = (@kostInCol + 1) * it.bilance.index * (@kostSide + 1)
        l += (it.index % @kostInCol) * @kostSide
        l += 0.5 * @kostSide
        "#{l}px"
      ..style \bottom ~>
        baseline = @kostSide * 5
        if it.direction == -1
          baseline -= 28 + 9
        shift = it.direction * @kostSide * Math.floor it.index / @kostInCol
        "#{baseline + shift}px"
      ..style \background-color ~>
        it.bilance.barva
      ..attr \data-tooltip -> void

  resortStrany: ->
    @strany
      ..enter!.append \div
        ..attr \class \strana
        ..append \div
          ..attr \class \popisek
          ..append \span .html -> if it.zkratka == "NEZ" then "Ostatní" else it.zkratka
      ..exit!remove!
      ..style \left ~> "#{(@kostInCol + 1) * it.index * (@kostSide + 1)}px"


  init: ->
    @kosti = @element.append \div
      ..attr \class \kosti

  resyncData: (data) ->
    @data = data
    if @contestedObvody
      for obvodId, datum of @data.obvody
        @contestedObvodyAssoc[obvodId].new = datum.kandidati.0
        @contestedObvodyAssoc[obvodId].new2 = datum.kandidati.1
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
  drawArrows: ->
    @arrows = @element.append \div
      ..attr \class \arrows
      ..append \div
        ..attr \class "arrow arrow-zisky"
        ..append \span
          ..html "Zisky"
        ..append \div
      ..append \div
        ..attr \class "arrow arrow-ztraty"
        ..append \span
          ..html "Ztráty"
        ..append \div

