window.ig.DownloadCache = class DownloadCache
  ->
    @items = {}
    @prefix = "//smzkomunalky.blob.core.windows.net/vysledky-2kolo/"
    # @prefix = "//smzkomunalky.blob.core.windows.net/vysledky/"

  get: (dataType, cb) ->
    item = @getItem dataType
    <~ item.get
    cb null, item.data

  getItem: (dataType) ->
    if @items[dataType] then that else @create dataType

  create: (dataType) ->
    url = switch dataType
      | "senat"
        @prefix + "senat.json"
      | "obce"
        @prefix + "obce.json"
      | otherwise
        @prefix + dataType + ".json"
    @items[dataType] = new CacheItem url

  invalidate: (dataType) ->
    @items[dataType]?.invalidate!

class CacheItem
  (@url) ->
    window.ig.Events @
    @valid = no
    @downloading = no
    @data = null
    setInterval @~checkLiveIsWorking, 60_000
    # <~ setTimeout _, 2000
    # @url .= replace '/vysledky-2kolo/' '/vysledky/'
    # @invalidate!


  get: (cb) ->
    if @valid
      cb null, @data
    else if @downloading
      @once \downloaded -> cb null it
    else
      <~ @download!
      cb null @data

  download: (cb) ->
    @downloading = yes
    (err, data) <~ window.ig.utils.download @url
    @data = data
    @data.obvody_array = for obvodId, datum of @data.obvody
      datum.obvodId = (parseInt obvodId, 10)
      datum.hlasu = 0
      for senator in datum.kandidati
        datum.hlasu += that if senator.hlasu
        senator.data = window.ig.senatori["#{obvodId}-#{senator.id}"]
      datum.kandidati.sort (a, b) -> b.hlasu - a.hlasu
      if datum.kandidati.0.hlasu > datum.hlasu / 2
        datum.obvodDecided = true
      datum

    @valid = yes
    @downloading = no
    @emit \downloaded data
    cb? null data

  invalidate: ->
    if @_events['downloaded']?length
      @download!
    else
      @valid = no

  checkLiveIsWorking: ->
    if not window.ig.liveUpdater.isOnline!
      @invalidate!
