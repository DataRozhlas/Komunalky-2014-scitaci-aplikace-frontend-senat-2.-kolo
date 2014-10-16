require! {
  fs
  xml2js
  iconv.Iconv
}
suffix = "_2010"
suffix = ""
iconv = new Iconv 'cp1250' 'utf-8'
zkratky_barvas =
  "KDU-ČSL"      : '#FEE300'
  "SZ"           : '#0FB103'
  "ČSSD"         : '#FEA201'
  "KSČM"         : '#F40000'
  "ODS"          : '#1C76F0'
  "VV"           : '#66E2D8'
  "DSSS"         : '#B55E01'
  "HLAVU VZHŮRU" : '#66E2D8'
  "Piráti"       : '#504E4F'
  "TOP 09"       : '#B560F3'
  "LEV 21"       : '#990422'
  "ANO 2011"     : '#5434A3'
  "Úsvit"        : '#B3C382'

(err, data) <~ fs.readFile "#__dirname/../data/cns#suffix.xml"
data = iconv.convert data
(err, xml) <~ xml2js.parseString data.toString!
strany = {}
xml.CNS.CNS_ROW.forEach ->
  zkratka = it.ZKRATKAN8.0
  nstrana = it.NSTRANA.0
  nazev = it.NAZEV_STRN.0
  barva = zkratky_barvas[zkratka]
  strany[nstrana] = {zkratka, nazev, barva}

(err, data) <~ fs.readFile "#__dirname/../data/serk#suffix.xml"
data = iconv.convert data
(err, xml) <~ xml2js.parseString data.toString!
# xml.SE_REGKAND.SE_REGKAND_ROW.length = 1

kandidati = xml.SE_REGKAND.SE_REGKAND_ROW.map (kandidat) ->
  stranaObj = strany[kandidat.NSTRANA.0]
  obvod = kandidat.OBVOD.0
  id = kandidat.CKAND.0
  jmeno = kandidat.JMENO.0
  prijmeni = kandidat.PRIJMENI.0
  strana = stranaObj.nazev
  zkratka = stranaObj.zkratka
  barva = stranaObj.barva
  [obvod, id, jmeno, prijmeni, strana, zkratka, barva].join "\t"


fs.writeFile "#__dirname/../data/senat.tsv", kandidati.join "\n"
# console.log strany
