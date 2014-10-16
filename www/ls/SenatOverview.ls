utils = window.ig.utils
senatStrany =
  "KSČM"    : [6 \#e3001a ]
  "ČSSD"    : [1 \#f29400 ]
  "SZ"      : [5 \#0FB103 ]
  "ANO2011" : [4 \#5434A3 ]
  "KDU-ČSL" : [3 \#FEE300 ]
  "ODS"     : [2 \#006ab3 ]
  "TOP09"   : [7 \#7c0042 ]

window.ig.SenatOverview = class SenatOverview
  (@parentElement, @downloadCache, @displaySwitcher) ->
    @element = @parentElement.append \div
      ..attr \class \senat
    @scrollable = @element.append \div
      ..attr \class \scrollable
    @scrollable.append \h2
      ..html "Konečné výsledky senátních voleb"
    @obvody_meta = window.ig.senat_obvody_meta
    @oldSenatElm = @scrollable.append \div
      ..append \h3 .html "Dosavadní složení senátu"
      ..attr \class "old-senat senat-overview"
    @newSenatElm = @scrollable.append \div
      ..append \h3 .html "Volené mandáty"
      ..attr \class "new-senat senat-overview"
    @senatPopisky = @oldSenatElm.append \div
      ..attr \class \senat-popisky
    @obvodyElm = @scrollable.append \div
      ..attr \class \obvody

    backbutton = utils.backbutton @element
      ..on \click ~> @displaySwitcher.switchTo \firstScreen

    (err, data) <~ @downloadCache.get "senat"
    @oldSenat = {}
    lf = String.fromCharCode 13
    for line in window.ig.data.old_senat.split "\n"
      [obvodId, jmeno, strana] = line.split "\t"
      obvodId = parseInt obvodId, 10
      continue unless obvodId
      strana .= replace lf, ''
      color = senatStrany[strana]?1
      ordering = senatStrany[strana]?0 || 99
      @oldSenat[obvodId] =
        old: {jmeno, strana, color}
        contested: data.obvody[obvodId] != void
        ordering: ordering
        obvodId: obvodId
    @obvodElements = {}
    @senatObvody = for obvodId, obvod of data.obvody
      @oldSenat[obvodId].new = obvod
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
        @senatPopisky.append \div
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
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b><br>"
        if 0 == it.obvodId % 3
          out += "<br>Obvod obhajuje #{it.old.jmeno}, #{it.old.strana}"
        else
          out += "<br>#{it.old.jmeno}, #{it.old.strana}"
        out

    @newSenatObvody = @newSenatElm.selectAll \div.new-obvod .data senatori .enter!append \div
      ..attr \class "obvod new-obvod"
      ..append \div .attr \class \old
      ..classed \contested (.new)
      ..style \left (d, i) ->
        "#{d.col * kostSide}px"
      ..style \top (d, i) ->
        "#{d.row * kostSide}px"
      ..append \div .attr \class \first
      ..append \div .attr \class \second
      ..on \click ~> @highlight it.obvodId
  top: ->
    @scrollable.0.0.scrollTop = 0

  updateAllSenat: ->
    @newSenatObvody.filter (.new)
      ..selectAll \.first
        ..style \background-color (it, i) ->
          if it.new.kandidati.0.hlasu
            it.new.kandidati.0.data?barva || utils.getStranaColor i
          else
            '#bbb'
      ..selectAll \.second
        ..style \background-color (it, i) ->
          if it.new.kandidati.1.hlasu
            it.new.kandidati.1.data?barva || utils.getStranaColor i
          else
            '#bbb'
      ..attr \data-tooltip ~>
        out = ""
        out += "<b>Senátní obvod č. #{it.obvodId}: #{@obvody_meta[it.obvodId].nazev}</b><br>"
        if it.new && it.new.kandidati.0.hlasu
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

  highlight: (obvodId) ->
    obvodId = obvodId.toString!
    for id, obvodElm of @obvodElements
      obvodElm.classed \highlight id == obvodId
      if id == obvodId
        top = obvodElm.0.0.offsetTop
        @scrollable.0.0.scrollTop = top - 40
