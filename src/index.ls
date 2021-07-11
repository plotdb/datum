datum = 
  _sep: \-
  # there are two types of data:
  #  - `db`: {head: [...], body: [{ ... }, ... ]} or [{ ... }, ... ]
  #  - `sheet`: [[ ...], ... ]
  format: ->
    if !it or !Array.isArray(it) or (it.0 and !Array.isArray(it.0)) => return \db
    return \sheet

  # convert db/sheet type to sheet type
  as-sheet: (obj) ->
    if @format(obj) == \sheet => return obj
    if Array.isArray(obj) => obj = {head: [k for k of obj.0], body: obj}
    sheet = [obj.head] ++ obj.body.map((b) -> obj.head.map (h) -> b[h])
    return sheet

  # convert sheet/db type to db type
  as-db: (obj, name = 'unnamed') ->
    if @format(obj) == \sheet =>
      json = do
        name: name
        head: obj.0
        body: obj.slice 1 .map (b) ->
          Object.fromEntries obj.0.map (h,i) -> [h, b[i]]
      return json
    if Array.isArray(obj) =>
      return {name, head: [k for k of obj.0], body: obj}
    if !obj.name => obj.name = 'unnamed'
    return obj

  concat: (ds) ->
    ds = ds.map (d) -> data.as-db d
    head = ds.0.head
    body = []
    for i from 0 til ds.length =>
      body ++= ds[i].body.map((d) -> Object.fromEntries(head.map (h) -> [h, d[h]]))
    return {name: ds.0.name, head, body}

  join: (d1, d2, jc) ->
    sep = @_sep
    [d1, d2] = [d1, d2].map (d) -> datum.as-db d
    [h1, h2] = [d1.head, d2.head]
    [b1, b2] = [d1.body, d2.body]
    [n1, n2] = [d1.name or \1, d2.name or \2]
    s1 = n1.split(sep)
    s2 = n2.split(sep)
    for i from 0 til s1.length => if s1[i] != s2[i] => break
    [n1, n2] = [s1.slice(i).join(sep), s2.slice(i).join(sep)]

    if !jc => jc = h1.filter (h) -> (~h2.indexOf(h))
    head = (
      jc ++ 
      h1.filter((h) -> !(h in jc)).map((h)-> if h in h2 => "#n1#sep#h" else h) ++
      h2.filter((h) -> !(h in jc)).map((h)-> if h in h1 => "#n2#sep#h" else h)
    )
    ret = b1.map (r1) ->
      matched = b2.filter (r2) -> !(jc.filter(-> r2[it] != r1[it]).length)
      if !matched.length => matched = [{}]
      ret = matched.map (r2) ->
        Object.fromEntries(
          jc.map((h) -> [h, r1[h]]) ++
          h1.filter((h) -> !(h in jc)).map((h)-> [(if h in h2 => "#n1#sep#h" else h), r1[h]]) ++
          h2.filter((h) -> !(h in jc)).map((h)-> [(if h in h1 => "#n2#sep#h" else h), r2[h]])
        )
      return ret
    body = ret.reduce(((a,b) -> a ++ b),[])

    return {
      name: d1.name or 'unnamed'
      head: head
      body: body
    }

  unjoin: (data, cols) ->
    data = @as-db data
    head = ([] ++ data.head)

  split: (data, col) ->
    data = @as-db data
    head = ([] ++ data.head)
    if !(~(idx = head.indexOf col)) => return data
    head.splice idx, 1
    hash = {}
    data.body.filter (d) -> hash[][d[col]].push d
    ret = []
    for k,v of hash => ret.push {name: "#{data.name or 'unnamed'}#{@_sep}#k", head: head, body: v}
    return ret

  pivot: (opt = {}) ->
    {data, col, join-col} = opt
    ds = @split data, col
    base = ds.splice 0, 1 .0
    for i from 0 til ds.length =>
      base = @join base, ds[i], join-col
    return base

  unpivot: (data, cols = [], name = "item", order = 0) ->
    sep = @_sep
    data = @as-db data
    hs = data.head
      .filter -> !(it in cols)
      .map -> it.split(sep)
    vals = Array.from(new Set(hs.map -> it[order]))
    tables = vals.map (v) ->
      _cols = cols.map(->[it, it])
      _hs = hs
        .filter(->it[order] == v)
        .map(->
          [
            it.join(sep),
            it.filter((d,i) -> i != order).join(sep)
          ]
        )
      {
        name: data.name
        head: cols ++ [name] ++ _hs.map(-> it.1)
        body: data.body.map (b) ->
          Object.fromEntries([[name, v]] ++ (_cols ++ _hs).map (h) -> [h.1,b[h.0]])
      }
    ret = @concat tables
    return ret

  group: (opt = {}) ->
    {data,col,aggregator,group-func} = opt
    if !group-func => group-func = (->it)
    if !aggregator => aggregator = {}
    col = if Array.isArray(col) => col else [col]
    data = @as-db data
    hs = data.head.filter -> !(it in col) and (aggregator[it] != null)
    keys = Array.from(new Set(data.body.map (b) -> JSON.stringify(Object.fromEntries(col.map -> [it, b[it]]))))
    hash = {}
    keys.map (raw) ->
      rkey = JSON.parse(raw)
      gkey = {}
      for k,v of rkey => gkey[k] = if typeof(group-func) == \function => group-func(v) else group-func[k](v)
      gkey = JSON.stringify(gkey)
      if !hash[gkey] => hash[gkey] = new Set!
      hash[gkey].add raw
    newkeys = [k for k of hash]
    ret = newkeys.map (nk) ->
      list = Array.from(hash[nk])
      nk = JSON.parse(nk)
      list = list
        .map (k) ->
          k = JSON.parse(k)
          data.body.filter (b) -> col.filter((c) -> b[c] != k[c]).length == 0
        .reduce(((a,b) -> a ++ b), [])
      ret = Object.fromEntries(
        hs.map (h) ->
          ls = list.map((l) -> l[h])
          ret = if aggregator[h] => aggregator[h] ls else ls.length
          [h,ret]
      )
      col.map (c) -> ret[c] = nk[c]
      ret
    return {head: (col ++ hs), body: ret, name: data.name}

  agg:
    average: -> it.reduce(((a,b) -> a + (if isNaN(+b) => 0 else +b)),0) / (it.length or 1)
    sum: -> it.reduce(((a,b) -> a + (if isNaN(+b) => 0 else +b)),0)
    count: -> it.length
    first: -> it.0 or ''

if module? => module.exports = datum
else if window? => window.datum = datum
