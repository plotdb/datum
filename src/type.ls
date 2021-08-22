datum.type =
  R: (opt = {}) ->
    data = opt.data
      .filter -> !(!it or "#{it}".trim! == '')
    len = data
      .filter -> !isNaN(parseFloat(it))
      .length
    r = (len / data.length)
    o = datum.type.O opt
    if o == r or o > 0.9 => r = o * 0.99
    r

  O: (opt = {}) ->
    data = [] ++ opt.data
    data.sort (a,b) -> b - a
    hash = {}
    for i from 1 til data.length =>
      if isNaN(data[i]) or isNaN(data[i - 1]) =>
        hash[if data[i] > data[i - 1] => "#{data[i]}:#{data[i - 1]}" else "#{data[i - 1]}:#{data[i]}"] = true
      else delta = data[i] - data[i - 1]
      hash[delta] = true
    o = 1 / ([k for k of hash].filter(->it != \0).length or 2)

  N: (opt={}) ->
    n = 1 - (datum.type.R opt)
    c = datum.type.C opt
    if c > 0.85 => n = c * 0.99
    n


  C: (opt={}) ->
    len = Array.from(new Set(opt.data)).length 
    maxlen = opt.data.length
    ret = (1 - (((len - 2) >? 0) / maxlen) - (1 / maxlen)) >? 0 <? 1
    if datum.type.R(opt) => ret = ret * 0.9
    return ret

  get: (dataset) ->
    {head, body} = datum.as-db dataset
    type = []
    for key in head =>
      d = body.map -> it[key]
      list = <[R O N C]>.map (t) ~> [t, datum.type[t]({data: d})]
      list.sort (a,b) -> b.1 - a.1
      type.push do
        key: key
        types: Object.fromEntries(list)
        type: list.0.0
    return type

  bind: (dataset = [], dimension = {}, datatypes) ->
    if !datatypes => datatypes = datum.type.get dataset
    dims = [{k,v} for k,v of dimension].filter -> !it.v.passive
    dims.sort (a,b) -> # which dimension bind first?
      ret = (a.v.priority or 100) - (b.v.priority or 100)
      if ret != 0 => return ret
      # tie in priority - then use type to decide. C > O > N > R
      [ma,mb] = [(a.v.type or \R), (b.v.type or \R)].map (t) ->
        Math.min.apply Math, [0 til t.length].map (i) -> "CONR".indexOf(t[i])
      return ma - mb
    for dim in dims =>
      dim.bind = null
      ts = dim.v.type or \RNOC
      for i from 0 til ts.length =>
        t = ts[i]
        datatypes.sort (a, b) ->
          ret = (b.types[t] or 0) - (a.types[t] or 0)
          if b.types[t] == a.types[t] and t == \R => return (a.types.O or 0) - (b.types.O or 0)
          return ret
        for i from 0 til datatypes.length =>
          dt = datatypes[i]
          if dt.types[t] < 0.5 or dt.used or (t == \C and dt.types.R > 0.5) => continue
          dim.bind = if dim.v.multiple => [dt] else dt
          dt.used = true
          break
        # once we got the best match, we don't have to try other datatype
        # otherwise priority will get inversed.
        if dim.bind => break
    for dim in dims =>
      if !dim.v.multiple => continue
      ts = dim.v.type or \RNOC
      for i from 0 til ts.length =>
        t = ts[i]
        datatypes.sort (a, b) ->
          ret = (b[t] or 0) - (a[t] or 0)
          if b[t] == a[t] and t == \R => return (a.O or 0) - (b.O or 0)
          return ret
        for i from 0 til datatypes.length =>
          dt = datatypes[i]
          if dt.types[t] < 0.5 or dt.used or (t == \C and dt.types.R > 0.5) => continue
          dim.bind.push dt
          dt.used = true
    ret = {}
    for dim in dims => if dim.bind =>
      ret[dim.k] = dim.bind
      (if Array.isArray(dim.bind) => dim.bind else [dim.bind]).map -> delete it.used
    return ret

