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
    @kandidati.sort (a, b) -> b.hlasu - a.hlasu
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
    @kandidatiElm.selectAll \span.kandidat .data @kandidati .enter!append \span
      ..attr \class (d, i) -> "kandidat kandidat-#i"
      ..append \span
        ..attr \class \name
        ..html ~>
          if it.data
            "#{it.data.jmeno} #{it.data.prijmeni}"
          else
            "Zatím neznámý"
      ..append \span
        ..attr \class \procent
        ..html ~> " #{utils.percentage it.hlasu / celkemHlasu} %"
      ..append \span
        ..attr \class \strana-kost
        ..style \background-color ~> it.data?barva || '#aaa'
      ..append \span
        ..attr \class \strana
        ..html ~>
          if it.data
            " (#{it.data.zkratka || it.data.strana})"
          else
            void
      ..append \span
        ..attr \class \delim
        ..html ", "
      ..attr \data-tooltip ~> "#{it.hlasu} hlasů"

  destroy: ->
    @element.remove!
    @resource.off \downloaded @onDownload

