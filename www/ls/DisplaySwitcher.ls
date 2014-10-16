window.ig.DisplaySwitcher = class DisplaySwitcher
  ({@firstScreen, @obec, @senat}) ->

  switchTo: (target, ...args) ->
    switch target
    | "firstScreen"
      @setActive "firstScreen"
      try
        window.top.location.hash = '#' + "-"
      catch e
        console?log? e
    | "senat"
      @setActive "senat"
      if args.length
        @senat.highlight ...args
      else
        @senat.top!
      console.log window.top.location
      try
        window.top.location.hash = '#' + "senat"
      catch e
        console?log? e
    | otherwise
      @obec.display target
      @setActive "obec"
      try
        window.top.location.hash = '#' + target.id
      catch e
        console?log? e

  setActive: (activeField) ->
    for field in <[firstScreen obec senat]>
      continue if field is activeField
      @[field].element.classed \disabled true
    @[activeField].element.classed \disabled false
