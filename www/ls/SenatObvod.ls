utils = window.ig.utils
window.ig.SenatObvod = class SenatObvod
  (@parentElement, @obvodId) ->
    @senatori = window.ig.senatori
    @resource = window.ig.downloadCache.getItem "senat" # fuck DI!
    @element = @parentElement.append \div
      ..attr \class \senat-obvod
    supplemental = @element.append \div
      ..attr \class "supplemental supplemental-mini"
      ..append \div
        ..attr \class \secteno
        ..append \h3 .html "Sečteno"
        ..append \span
          ..attr \class \value
        ..append \div
          ..attr \class \progress
          ..append \div
            ..attr \class \fill
      ..append \div
        ..attr \class \ucast
        ..append \h3 .html "Účast"
        ..append \span
          ..attr \class \value
        ..append \div
          ..attr \class \progress
          ..append \div
            ..attr \class \fill
    @sectenoValue = supplemental.select ".secteno .value"
    @sectenoFill = supplemental.select ".secteno .fill"
    @ucastValue = supplemental.select ".ucast .value"
    @ucastFill = supplemental.select ".ucast .fill"

    @kandidatiElm = @element.append \div
      ..attr \class \kandidati
    (err, data) <~ @resource.get
    @onDownload data
    @resource.on \downloaded @onDownload

  onDownload: (data) ~>
    @data = data.obvody[@obvodId]
    return unless @data
    @kandidati = @data.kandidati
    if @kandidati.length > 2 then @kandidati.length = 2
    @kandidati.sort (a, b) -> b.id - a.id
    @kandidatiElm.selectAll \span.kandidat .remove!
    celkemHlasu = 0
    @kandidati.forEach ~>
      it.data = @senatori["#{@obvodId}-#{it.id}"]
      celkemHlasu += it.hlasu

    @sectenoValue.html ~>
      n = utils.formatNumber 100 * @data.okrsky_spocteno / @data.okrsky_celkem
      if n == 100 and @data.okrsky_spocteno != @data.okrsky_celkem
        n = 99
      "#{n}&nbsp;%"
    @sectenoFill.style \width ~>
      "#{100 * @data.okrsky_spocteno / @data.okrsky_celkem}%"
    @ucastValue.html ~>
      "#{utils.formatNumber 100 * @data.volilo / (@data.volicu || 1)}&nbsp;%"
    @ucastFill.style \width ~>
      "#{100 * @data.volilo / @data.volicu}%"
    return unless @kandidati.0.hlasu
    @kandidatElm = @kandidatiElm.selectAll \span.kandidat .data @kandidati .enter!append \span
      ..attr \class (d, i) -> "kandidat kandidat-#i"
      ..append \div
        ..attr \class \name
      ..append \div
        ..attr \class \strana
        ..html ~>
          if it.data
            "#{it.data.zkratka || it.data.strana}"
          else
            void
      ..append \div
        ..attr \class \procent
      ..append \div
        ..attr \class \absolute
      ..append \img
        ..attr \src ~> "./img/hlavy-res/#{@obvodId}-#{it.id}.jpg"
    @kandidatiElm.append \div
      ..attr \class \mid
      ..html "50 %"
      ..append \div
        ..attr \class \arrow
    @fillElm = @kandidatiElm.append \div
      .attr \class \bar
      .append \div
        .attr \class \container
        .selectAll \.fill .data [0, 1] .enter!append \div
          ..attr \class \fill
          ..style \background-color (d, i) ~> @kandidati[i].data.barva || '#999'

    @kandidatElm
      ..select \div.name .html ~>
        if it.data
          "#{it.data.jmeno} #{it.data.prijmeni}"
        else
          "Zatím neznámý"
      ..select \div.absolute .html ~> " #{utils.formatNumber it.hlasu} hlasů"
      ..select \div.procent .html ~> " #{utils.percentage it.hlasu / celkemHlasu} %"
    @fillElm.style \width (d, i) ~>
        "#{@kandidati[i].hlasu / celkemHlasu * 100}%"


  destroy: ->
    @element.remove!
    @resource.off \downloaded @onDownload

