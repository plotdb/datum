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
    ds = ds.map (d) -> datum.as-db d
    head = ds.0.head
    body = []
    for i from 0 til ds.length =>
      body ++= ds[i].body.map((d) -> Object.fromEntries(head.map (h) -> [h, d[h]]))
    return {name: ds.0.name, head, body}

  _join-all: (opt = {}) ->
    sep = @_sep
    {ds, join-cols} = opt
    ds = ds.map -> datum.as-db it
    hs = ds.map -> it.head
    bs = ds.map -> it.body
    metas = ds.map -> it{unit, mag, type}

    # we have multiple tables. we want to join them but some columns may have the same name.
    # so we prefix them with table names.
    # yet we are probably joining tables from the same table due to pivoting.
    # in this case table names share common part. we only need to prefix not-common part.
    ns = ds.map (d,i) -> d.name or "#{i + 1}"
    ss = ns.map -> it.split(sep)
    idx = -1
    for i from 0 til ss.0.length =>
      for j from 1 til ss.length =>
        if ss[j][i] != ss[0][i] =>
          idx = i
          break
      if idx >= 0 => break
    # not-common part table names
    if idx < 0 => ns = ds.map (d,i) -> "#{i + 1}"
    else ns = ss.map -> it.slice(idx).join(sep)

    # count how many times a header name appear in all tables.
    heads = {}
    hs.map (head) -> head.map (h) -> heads[h] = (heads[h] or 0) + 1

    # join-cols is the array of columns to join.
    # if omitted, we use intersection of all headers for it.
    if !join-cols => join-cols = [k for k of hs].filter -> hs[it] == hs.length

    # rename head (h) based on table name (n) if necessary.
    rehead = (n,h) ->
      # simple-head is true - force to not rename.
      if opt.simple-head => return n
      # h appears multiple times. we need to prefix it to prevent collision.
      if heads[h] > 1 => return "#n#sep#h"
      # h only appears once. no need to prefix it.
      return h

    # head mapping.
    hm = hs.map (oh,i) ->
      map = Object.fromEntries(
        oh.map (h) -> [ h, (if !(h in join-cols) => rehead(ns[i],h) else h) ]
      )
    # all headers after joining.
    nhs = hs.map (oh,i) ->
      nh = oh
        .filter (h) -> !(h in join-cols) # common parts are already added above.
        .map (h) -> rehead ns[i], h      # rename h if necessary.
    head = ([join-cols] ++ nhs).reduce(((a,b) -> a ++ b),[])

    # group rows by values in join-cols
    join-values = {}
    bs.map (body,i) ->
      body.map (b) ->
        ret = {}
        index = JSON.stringify(Object.fromEntries(join-cols.map (h) -> [h,b[h]]))
        # rehead body based on head mapping `hm`
        for k,v of b => ret[hm[i][k]] = v
        join-values[][index].push ret
    body = []
    for k,list of join-values =>
      body.push list.reduce(((a,b) -> a <<< b), {})

    base = {mag: {}, unit: {}, type: {}}
    metas.map (obj, i) ->
      <[mag unit type]>.map (n) ->
        if !obj[n] => return
        for k,v of obj[n] => base[n][hm[i][k]] = v

    return {
      name: ds.0.name or 'unnamed'
      head: head
      body: body
    } <<< base


  join: (opt = {}) ->
    {d1, d2, join-cols} = opt
    if opt.ds => return @_join-all opt
    rehead = if opt.simple-head => ((a,b) -> a) else ((a,b) -> "#a#sep#b")
    jc = join-cols
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

    head = [
      jc.map(-> [it, it]) ++ h1.filter((h) -> !(h in jc)).map((h)-> [h, (if h in h2 => rehead(n1,h) else h)])
      h2.filter((h) -> !(h in jc)).map((h)-> [h, (if h in h1 => rehead(n2,h) else h)])
    ]

    base = {}
    <[mag unit type]>.map (n) ->
      base[n] = {}
      if d1[n] => head.0.map (h) -> base[n][h.1] = d1[n][h.0]
      if d2[n] => head.1.map (h) -> base[n][h.1] = d2[n][h.0]

    head = (head.0 ++ head.1).map -> it.1

    ret = b1.map (r1) ->
      matched = b2.filter (r2) -> !(jc.filter(-> r2[it] != r1[it]).length)
      if !matched.length => matched = [{}]
      ret = matched.map (r2) ->
        Object.fromEntries(
          jc.map((h) -> [h, r1[h]]) ++
          h1.filter((h) -> !(h in jc)).map((h)-> [(if h in h2 => rehead(n1,h) else h), r1[h]]) ++
          h2.filter((h) -> !(h in jc)).map((h)-> [(if h in h1 => rehead(n2,h) else h), r2[h]])
        )
      return ret
    body = ret.reduce(((a,b) -> a ++ b),[])

    return {
      name: d1.name or 'unnamed'
      head: head
      body: body
    } <<< base

  split: ({data, col}) ->
    data = @as-db data
    head = ([] ++ data.head)
    if !(~(idx = head.indexOf col)) => return data
    head.splice idx, 1
    base = {}
    <[mag unit type]>.map (n) ->
      base[n] = {} <<< data[n]
      delete base[n][col]
    hash = {}
    data.body.filter (d) -> hash[][d[col]].push d
    ret = []
    for k,v of hash =>
      ret.push {
        name: "#{data.name or 'unnamed'}#{@_sep}#k"
        head: head
        body: v
      } <<< JSON.parse(JSON.stringify base)
    return ret

  pivot: (opt = {}) ->
    {data, col, join-cols, simple-head} = opt
    if !(simple-head?) => simple-head = false
    ds = @split {data, col}
    ds = ds.map (d) ~> @shrink {data: d, cols: d.head.filter -> it != col}
    return @join {ds, join-cols, simple-head}

  # TODO unpivot mag, unit and type too
  unpivot: (opt = {}) ->
    {data, cols, name, order} = opt
    if !name => name = \item
    if !(order?) => order = 0
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
    {data,cols,aggregator,group-func} = opt
    if !aggregator => aggregator = {}
    cols = if Array.isArray(cols) => cols else [cols]
    data = @as-db data
    hs = data.head.filter -> !(it in cols) and (aggregator[it] != null)
    keys = Array.from(new Set(data.body.map (b) -> JSON.stringify(Object.fromEntries(cols.map -> [it, b[it]]))))
    hash = {}
    keys.map (raw) ->
      rkey = JSON.parse(raw)
      if typeof(group-func) == \function => gkey = group-func(rkey)
      else
        _gf = group-func or {}
        gkey = {}
        for k,v of rkey => gkey[k] = if typeof(_gf[k]) == \function => _gf[k](v) else v
      (if Array.isArray(gkey) => gkey else [gkey]).map (k) ->
        k = JSON.stringify(k)
        if !hash[k] => hash[k] = new Set!
        hash[k].add raw
    newkeys = [k for k of hash]
    ret = newkeys.map (nk) ->
      list = Array.from(hash[nk])
      nk = JSON.parse(nk)
      list = list
        .map (k) ->
          k = JSON.parse(k)
          data.body.filter (b) -> cols.filter((c) -> b[c] != k[c]).length == 0
        .reduce(((a,b) -> a ++ b), [])
      ret = Object.fromEntries(
        hs.map (h) ->
          ls = list.map((l) -> l[h])
          ret = if aggregator[h] => aggregator[h] ls else ls.length
          [h,ret]
      )
      cols.map (c) -> ret[c] = nk[c]
      ret
    return {head: (cols ++ hs), body: ret, name: data.name}

  agg:
    average: -> it.reduce(((a,b) -> a + (if isNaN(+b) => 0 else +b)),0) / (it.length or 1)
    sum: -> it.reduce(((a,b) -> a + (if isNaN(+b) => 0 else +b)),0)
    count: -> it.length
    first: -> it.0 or ''

  shrink: ({data, cols}) ->
    data = @as-db data
    data.head = data.head.filter(-> it in cols)
    data.body = data.body.map (b) -> Object.fromEntries(data.head.map (h) -> [h, b[h]])
    <[unit mag type]>.filter(->data[it]).map (n) ->
      data[n] = Object.fromEntries(data.head.map (h) -> [h, data[n][h]])
    return data

  rename: ({data, map}) ->
    data = @as-db data
    data.body = data.body.map (b) ->
      Object.fromEntries data.head.map (h) -> [(if map[h] => that else h), b[h]]
    <[unit mag type]>.filter(-> data[it]).map (n) ->
      data[n] = Object.fromEntries(data.head.map (h) -> [map[h] or h, data[n][h]])
    data.head = data.head.map (h) -> if map[h] => that else h
    return data

if module? => module.exports = datum
else if window? => window.datum = datum
