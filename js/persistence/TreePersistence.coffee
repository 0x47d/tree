util        = require '../utils/util.coffee'
dedup = {}  # XX wrong layer

pending = {}
delayedDependencies = []

window.urb.dependencyHandlers["data"] = (dep)-> # move to persistence?
  for type, dat of window.urb.dependencies
    if type is "data"
      window.urb.delDependency(dat)
  window.tree.actions.clearData()

module.exports =
  refresh: -> dedup = {}
  get: (path,query="no-query",cb) ->
    url = "/_tree-json#{util.basepath(path)}?#{@encode query}"
    return if dedup[url]
    dedup[url] = true
    pending[url] = true
    $.get url, {}, (data,status,xhr) ->  # XX on error
      delete pending[url]
      if urb.wasp?
        dep = urb.getXHRWasp(xhr)
        urb.sources[dep] = url # debugging info
        delayedDependencies.push dep
        if _.isEmpty pending
          delayedDependencies.map urb.addDataDependency
          delayedDependencies = []
      if cb then cb null,data
    
  put: (data,mark,appl,cb)->
    appl ?= /[a-z]*/.exec(mark)[0]
    urb.init -> urb.send data, {mark,appl}, cb

  waspElem: (a)->
    if urb.dependOnElem?
      urb.dependOnElem a
    
  encode: (list)->
    # convert {spur:'t', {kids:{plan:'t', snip:'r'}}} old format
    #  to ['spur' {kids:['plan' 'snip']}] new format
    list = for k,v of list 
      if _.isString v
        k
      else
        "#{k}": for k2,v2 of v
          k2
          
    list.map((elem)=>
      if _.isString elem
        return elem
      else
        for key,v of elem
          return key+"="+elem[key].join('+')
    ).join('&')
