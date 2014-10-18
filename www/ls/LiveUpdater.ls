window.ig.LiveUpdater = class LiveUpdater
  (@downloadCache) ->
    @lastMessage = new Date!getTime!
    try
      es = new EventSource "/sse/"
      es.onmessage = (event) ~>
        @lastMessage = new Date!getTime!
        len = event.data.length
        data = for i in [0 til len]
          event.data.charCodeAt i
        for code in data
          switch code
          | 1 => @update "obce"
          | 2 => @update "senat"
          | 4, 5 => console?log? "Hello"
          | 6 => window.location.reload!
          | otherwise =>
            @update @getObecId code

  isOnline: ->
    t = new Date!getTime!
    t - @lastMessage < 60_000

  update: (dataType) ->
    return unless dataType
    item = @downloadCache.items[dataType]
    item?invalidate!

  getObecId: (code) ->
    code -= 20
    if window.ig.suggester.suggestions
      obec = window.ig.suggester.suggestions[code]
      if obec
        return obec.id
    return null
