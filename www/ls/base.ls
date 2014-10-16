init = ->
  new Tooltip!watchElements!


  container = d3.select ig.containers.base
  firstScreen =
    element: container.append \div .attr \class "firstScreen"
  window.ig.downloadCache = downloadCache = new window.ig.DownloadCache
  window.ig.liveUpdater = liveUpdater = new window.ig.LiveUpdater downloadCache
  senatKosti = new window.ig.SenatKosti firstScreen.element, downloadCache
    ..init!

  senat = new window.ig.SenatOverview container, downloadCache
    ..element.classed \disabled yes

window.ig.strany = strany = {}
lf = String.fromCharCode 13
reLf = new RegExp lf, 'g'
window.ig.data.strany .= replace reLf, ''
window.ig.data.senat .= replace reLf, ''
for line in window.ig.data.strany.split "\n"
  [vstrana, nazev, zkratka, barva] = line.split "\t"
  strany[vstrana] = {nazev, zkratka, barva}

window.ig.senatori = senatori = {}
for senator in ig.data.senat.split "\n"
  [obvod, id, jmeno, prijmeni, strana, zkratka, barva] = senator.split "\t"
  senatori["#{obvod}-#{id}"] = {jmeno, prijmeni, strana, zkratka, barva}

window.ig.senat_obvody_meta = obvody_meta = {}
for line in window.ig.data.senat_obvody.split "\n"
  [id, nazev] = line.split "\t"
  obvody_meta[id] = {nazev}


if d3?
  init!
else
  window.onload = ->
    if d3?
      init!

