utils = window.ig.utils
barvy =
  "21": 53
  "24": 53
  "27": 53
  "54": 47

defaultBarva = 7

window.ig.SenatKosti = class SenatKosti implements utils.supplementalMixin
  (@baseElement, @downloadCache) ->
    @element = @baseElement.append \div
      ..attr \class \senatKosti
    heading = @element.append \h2
    @heading = heading.append \span
      ..attr \class \main
      ..html "Průběžné výsledky senátních voleb"

    @element.selectAll \.popisek .data <[Praha Brno Ostrava]> .enter!append \div
      ..attr \class -> "popisek #{it.toLowerCase!}"
      ..html -> it
      ..append \div
        ..attr \class \arrow

    sx = 800 / 509.8714
    @svg = @element.append \svg
      ..attr \width 509.8714 * sx
      ..attr \height 157.29874 * sx
      ..append \g
        ..attr \transform "scale(#sx)"
        ..html ig.data.obvody_svg
    @obvody = for i in [0 til 27]
      obvodId = (i + 1) * 3
      d = {data: null}
      @svg.select ".obvod-#{obvodId}"
        .datum d
      d
    @drawSupplemental!
    @obvody_meta = window.ig.senat_obvody_meta
    @obvodyElms = @svg.selectAll \.obvod

  redraw: ->
    if @data.okrsky_celkem == @data.okrsky_spocteno
      @heading.html "Celkové výsledky senatních voleb"

    @obvodyElms
      ..attr \data-tooltip (obvod) ~>
        strana = barvy[obvod.data.obvodId] || defaultBarva
        out = "<b>Senátní obvod č. #{obvod.data.obvodId}: #{@obvody_meta[obvod.data.obvodId].nazev}</b><br>"
        if not obvod.data.hlasu then obvod.data.hlasu = 1
        if obvod.data
          out += obvod.data.kandidati.slice 0, 2
            .map (kandidat, i) ->
              if kandidat.data
                "#{kandidat.data.jmeno} <b>#{kandidat.data.prijmeni}</b>: <b>#{utils.percentage kandidat.hlasu / obvod.data.hlasu} %</b> (#{kandidat.data.zkratka}, #{kandidat.hlasu} hl.)"
              else if i == 0
                "Zatím neznámý"
            .join "<br>"
        out += "<br>Obvod obhajuje #{window.ig.strany[strana].zkratka}, sečteno je #{utils.percentage obvod.data.okrsky_spocteno / obvod.data.okrsky_celkem}&nbsp;% hlasů"
        out += "<br><em>Klikněte pro podrobné výsledky</em>"
        out
      ..transition!
        ..duration 600
        ..style \fill ->
          it.data.kandidati.0.hlasu && it.data.kandidati.0.data.barva || \#aaa
    @updateSupplemental!


  init: (cb) ->
    @cacheItem = @downloadCache.getItem "senat"
    (err, data) <~ @cacheItem.get
    @cacheItem.on \downloaded (data) ~> @saveData data
    @saveData data
    cb?!

  saveData: (data) ->
    return unless data
    @data = data
    for datum, index in @data.obvody_array
      @obvody[index].data = datum
    @redraw!
