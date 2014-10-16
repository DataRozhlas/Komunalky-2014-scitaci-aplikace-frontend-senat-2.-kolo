window.ig.DownloadCache = class DownloadCache
  ->
    @items = {}
    @prefix = "//smzkomunalky.blob.core.windows.net/vysledky/"
    # @prefix = "/komunalky-14-backend/data/output_formatted/"

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
    @valid = yes
    @downloading = no
    @data = data
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
