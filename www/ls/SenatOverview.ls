utils = window.ig.utils
senatStrany =
  "KSČM"     : zkratka: "KSČM",      color: \#e3001a, countOld: 0, countNew: 0, fallbackOrdering: 5
  "ČSSD"     : zkratka: "ČSSD",      color: \#FEA201, countOld: 0, countNew: 0, fallbackOrdering: 1
  "SZ"       : zkratka: "SZ",        color: \#0FB103, countOld: 0, countNew: 0, fallbackOrdering: 4
  "ANO 2011" : zkratka: "ANO",       color: \#5434A3, countOld: 0, countNew: 0, fallbackOrdering: 6
  "KDU-ČSL"  : zkratka: "KDU-ČSL",   color: \#FEE300, countOld: 0, countNew: 0, fallbackOrdering: 3
  "ODS"      : zkratka: "ODS",       color: \#1C76F0, countOld: 0, countNew: 0, fallbackOrdering: 2
  "TOP 09"   : zkratka: "TOP",       color: \#7c0042, countOld: 0, countNew: 0, fallbackOrdering: 6
  "NEZ"      : zkratka: "NEZ",       color: \#999,    countOld: 0, countNew: 0, fallbackOrdering: 99

window.ig.SenatOverview = class SenatOverview
  (@parentElement, @downloadCache, @displaySwitcher) ->
    @element = @parentElement.append \div
      ..attr \class \senat
    @scrollable = @element.append \div
      ..attr \class \scrollable
    @scrollable.append \h2
      ..html "Nové složení senátu"
      ..append \span
        ..attr \class "subtitle"
        ..html "Zobrazit dosavadní složení senátu&hellip;"
        ..on \click ~>
          @showOldSenat!
          @scrollable.select 'h2 .subtitle' .remove!
    @obvody_meta = window.ig.senat_obvody_meta
    @newSenatElm = @scrollable.append \div
      ..attr \class "new-senat senat-overview"
    @oldSenatElm = @scrollable.append \div

    @senatPopisky = @newSenatElm.append \div
      ..attr \class \senat-popisky
    @obvodyElm = @scrollable.append \div
      ..attr \class \obvody

    @cacheItem = @downloadCache.getItem "senat"
    (err, data) <~ @cacheItem.get
    @cacheItem.on \downloaded (data) ~>
      @data = data
      @updateAllSenat!
    @data = data
    @newSenat = {}
    lf = String.fromCharCode 13
    for line in window.ig.data.old_senat.split "\n"
      [obvodId, jmeno, strana] = line.split "\t"
      obvodId = parseInt obvodId, 10
      continue unless obvodId
      strana .= replace lf, ''
      color = senatStrany[strana]?color
      stranaObj = if data.obvody[obvodId] is void
        s = senatStrany[strana] || senatStrany["NEZ"]
        s.countOld++
        s

      @newSenat[obvodId] =
        old: {jmeno, strana, color}
        contested: data.obvody[obvodId] != void
        stranaObj: stranaObj
        obvodId: obvodId
    @obvodElements = {}
    @senatObvody = for obvodId, obvod of data.obvody
      @newSenat[obvodId].new = obvod
      obvod.hlasu = 0
      for kandidat in obvod.kandidati
        obvod.hlasu += kandidat.hlasu

      @obvodElements[obvodId] = obvodElm = @obvodyElm.append \div
        ..attr \class \obvod
      obvodElm.append \h3
        ..append \span
          ..attr \class \nazev
          ..html "#{@obvody_meta[obvodId].nazev}"
        ..append \span
          ..attr \class \popisek
          ..html "Celorepublikové výsledky"
          ..on \click ~> @scrollable.0.0.scrollTop = 0
      new window.ig.SenatObvod obvodElm, obvodId
    @drawAllSenat!
    @updateAllSenat!

  drawAllSenat: ->
    @senatori = for obvod, senator of @newSenat
      senator

    @newSenatObvody = @newSenatElm.selectAll \div.old-obvod .data @senatori .enter!append \div
      ..attr \class "obvod old-obvod"
      ..classed \contested (.contested)
      ..append \div
        ..attr \class \old
        ..style \background-color (it, i) ->
          it.old.color || \#999
      ..attr \data-tooltip ~>
        out = ""
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b><br>"
        if 0 == it.obvodId % 3
          out += "<br>Obvod obhajuje #{it.old.jmeno}, #{it.old.strana}"
        else
          out += "<br>#{it.old.jmeno}, #{it.old.strana}"
        out

  top: ->
    @scrollable.0.0.scrollTop = 0

  updateAllSenat: (kandidatOrder = 0) ->
    kostSide = 28px
    rows = 4
    for obvodId, datum of @newSenat
      if @data.obvody[obvodId] isnt void
        {zkratka} = @data.obvody[obvodId].kandidati[kandidatOrder].data
        s = senatStrany[zkratka] || senatStrany["NEZ"]
        s.countNew++
        datum.stranaObj?countNew--
        datum.stranaObj = s

    @senatori.sort (a, b) ->
      | a.stranaObj.fallbackOrdering == 99 => 1
      | b.stranaObj.fallbackOrdering == 99 => -1
      | (b.stranaObj.countOld + b.stranaObj.countNew) - (a.stranaObj.countOld + a.stranaObj.countNew) => that
      | b.stranaObj.fallbackOrdering - a.stranaObj.fallbackOrdering => that
      | a.contested - b.contested => that
      | a.obvodId - b.obvodId => that
    row = -1
    col = -1.5
    lastStrana = null
    popisky = []
    for senator, index in @senatori
      row++
      if lastStrana != senator.stranaObj
        lastStrana = senator.stranaObj
        col += 1.5
        row = 0
        lastStrana.col = col
        popisky.push lastStrana
      if row >= rows
        row = 0
        col++
      senator.row = row
      senator.col = col
    @senatPopisky.selectAll \div.popisek .data popisky, (.zkratka)
      ..enter!append \div
        ..attr \class \popisek
        ..append \span
          ..attr \class \content
        ..append \div
          ..attr \class \arrow
      ..exit!remove!

    @senatPopisky.selectAll "div.popisek"
      ..select \.content .html (.zkratka)
      ..style \left -> "#{it.col * kostSide}px"

    @newSenatObvody
      ..style \left (d, i) ->
        "#{d.col * kostSide}px"
      ..style \top (d, i) ->
        "#{d.row * kostSide}px"
    @newSenatObvody.filter (.new)
      ..select \.old
        ..style \background-color (it, i) ->
          if it.new.kandidati[kandidatOrder].hlasu
            it.new.kandidati[kandidatOrder].data?barva || '#999'
          else
            '#999'
      ..attr \data-tooltip ~>
        out = ""
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b><br>"
        if it.new && it.new.kandidati[kandidatOrder].hlasu
          out += it.new.kandidati.slice 0, 2
            .map (kandidat, i) ->
              if kandidat.data
                "#{kandidat.data.jmeno} <b>#{kandidat.data.prijmeni}</b>: <b>#{utils.percentage kandidat.hlasu / it.new.hlasu} %</b> (#{kandidat.data.zkratka}, #{kandidat.hlasu} hl.)"
              else if i == 0
                "Zatím neznámý"
            .join "<br>"
        if it.obvodId % 3
          out += "<br>#{it.old.jmeno}, #{it.old.strana}"
        else
          out += "<br>Obvod obhajuje #{it.old.jmeno}, #{it.old.strana}"
        out

  showOldSenat: ->
    @oldSenatElm
      ..attr \class "old-senat senat-overview"
      ..append \h2
        ..html "Dosavadní složení senátu"
    @oldSenatPopisky = @oldSenatElm.append \div
      ..attr \class \senat-popisky
    @oldSenat = {}
    lf = String.fromCharCode 13
    for line in window.ig.data.old_senat.split "\n"
      [obvodId, jmeno, strana] = line.split "\t"
      obvodId = parseInt obvodId, 10
      continue unless obvodId
      strana .= replace lf, ''
      color = senatStrany[strana]?color
      ordering = senatStrany[strana]?fallbackOrdering || 99
      @oldSenat[obvodId] =
        old: {jmeno, strana, color}
        contested: no
        ordering: ordering
        obvodId: obvodId
    kostSide = 28px
    rows = 4
    senatori = for obvod, senator of @oldSenat
      senator
    senatori.sort (a, b) ->
      | a.ordering - b.ordering => that
      | a.contested - b.contested => that
      | a.obvodId - b.obvodId => that
    row = -1
    col = -1.5
    lastStrana = null
    for senator, index in senatori
      row++
      if lastStrana != senator.ordering
        lastStrana = senator.ordering
        col += 1.5
        row = 0
        @oldSenatPopisky.append \div
          ..html ->
            s = senator.old.strana
            if s == "STAN" then s = "Nezávislí"
            s
          ..style \left "#{col * kostSide}px"
          ..attr \class \popisek
          ..append \div
            ..attr \class \arrow
      if row >= rows
        row = 0
        col++
      senator.row = row
      senator.col = col
    newSenatori = senatori.filter (.new)
    utils.resetStranyColors!

    @oldSenatObvody = @oldSenatElm.selectAll \div.old-obvod .data senatori .enter!append \div
      ..attr \class "obvod old-obvod"
      ..classed \contested (.contested)
      ..style \left (d, i) ->
        "#{d.col * kostSide}px"
      ..style \top (d, i) ->
        "#{d.row * kostSide}px"
      ..append \div
        ..attr \class \old
        ..style \background-color (it, i) ->
          it.old.color || \#999
      ..attr \data-tooltip ~>
        out = ""
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b>"
        out += "<br>#{it.old.jmeno}, #{it.old.strana}"
        out

  highlight: (obvodId) ->
    obvodId = obvodId.toString!
    for id, obvodElm of @obvodElements
      obvodElm.classed \highlight id == obvodId
      if id == obvodId
        top = obvodElm.0.0.offsetTop
        @scrollable.0.0.scrollTop = top - 40
