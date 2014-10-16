utils = window.ig.utils
locations =
  "3": [5 46]
  "9": [10 48]
  "6": [12 33]
  "30": [16 35]
  "33": [17 10]
  "36": [21 16]
  "42": [23 41]
  "18": [16 52]
  "12": [13.5 69]
  "15": [23 67]
  "39": [29.5 21]
  "45": [29 33]
  "48": [33 37]
  "51": [31 62]
  "54": [31 85]
  "57": [37 73]
  "66": [38 51]
  "63": [44 61]
  "81": [42 85]
  "78": [46 73]
  "69": [49 59]
  "75": [48 47]
  "21": [59 43]
  "27": [61 28]
  "22": [66 38]
  "24": [69 29]
  "72": [78 15]
  "60": [66 73]

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
    sx = 800 / 509.8714
    @svg = @element.append \svg
      ..attr \width 509.8714 * sx
      ..attr \height 157.29874 * sx
      ..append \g
        ..attr \transform "scale(#sx)"
        ..html ig.data.obvody_svg
    @obvody = for [0 til 27] => {data: null}
    @drawSupplemental!
    @obvody_meta = window.ig.senat_obvody_meta
    @senatori = window.ig.senatori
    for senator in ig.data.senat.split "\n"
      [obvod, id, jmeno, prijmeni, strana, zkratka, barva] = senator.split "\t"
      @senatori["#{obvod}-#{id}"] = {jmeno, prijmeni, strana, zkratka, barva}

  redraw: ->
    if @data.okrsky_celkem == @data.okrsky_spocteno
      @heading.html "Celkové výsledky senatních voleb"
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
    @data.obvody_array = for obvodId, datum of @data.obvody
      datum.obvodId = (parseInt obvodId, 10)
      datum.hlasu = 0
      for senator in datum.kandidati
        datum.hlasu += that if senator.hlasu
        senator.data = @senatori["#{obvodId}-#{senator.id}"]
      datum.kandidati.sort (a, b) -> b.hlasu - a.hlasu
      if datum.kandidati.0.hlasu > datum.hlasu / 2
        datum.obvodDecided = true
      datum
    for datum, index in @data.obvody_array
      @obvody[index].data = datum
    @redraw!
