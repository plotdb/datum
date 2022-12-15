/*
api change:
 shrink: ({cols, keep}) 
*/
datum = (o={}) ->
  if !(@ instanceof datum) => return if o instanceof datum => o else new datum o
  @_sep = o.sep or \-
  if Array.isArray(o) or o.body => @from o
  else if o.data => @from o.data
  else @clear!
  @

itf =
  clear: -> @_d = h: [], b: [], n: ''
  clone: -> new datum(@as-sheet!)
  format: (o) ->
    return if !o or !Array.isArray(o) or (o.0 and !Array.isArray(o.0)) => \db
    else if o instanceof datum => \datum
    else \sheet

  # append (n) after a head name if the name has been used
  _dedup: (h) ->
    c = {}
    h = h.map (n) -> 
      while c[n] => n = "#n(#{c[n]++})"
      c[n] = 1
      n
    h

  from: (d = {}) ->
    @clear!
    if d instanceof datum => @_d = JSON.parse(JSON.stringify(d._d))
    else if @format(d) == \sheet =>
      d = JSON.parse JSON.stringify d
      d.map (r,i) ~> if i == 0 => @_d.h = r else @_d.b.push r
    else
      d = JSON.parse JSON.stringify d
      [h, b, n] = if Array.isArray(d) => [[k for k of (d.0 or {})], d]
      else [d.head, d.body, d.name]
      @_d.n = n or ''
      @_d.h = h
      # _b can be either Array or Object.
      @_d.b = b.map (_b) ~> if Array.isArray(_b) => _b else h.map -> _b[it]
    @_d.h = @_dedup @_d.h
    return @

  as-sheet: -> JSON.parse JSON.stringify([@_d.h] ++ @_d.b)
  as-db: ->
    @_d.h = h = @_dedup @_d.h
    return JSON.parse JSON.stringify(
      name: @_d.n
      head: @_d.h
      body: @_d.b.map (b) -> Object.fromEntries b.map((d,i) -> [h[i], d])
    )

  name: -> @_d.n or ''
  head: -> @_d.h
  body: -> @_d.b
  sep: -> if arguments.length => @_sep = it else @_sep

  concat: ->
    ds = [@] ++ Array.from(arguments).map(->datum.from it)
    hs = []
    ds.map (d) -> hs ++= d.head!
    hs = Array.from(new Set hs)
    bs = []
    body = []
    for i from 0 til ds.length =>
      [h,b] = [ds[i].head!, ds[i].body!]
      bs ++= b.map (d,i) -> hs.map -> if ~(j = h.indexOf(it)) => d[j] else undefined
    @_d.h = hs
    @_d.b = bs
    @

  shrink: ({cols, keep}) ->
    [k,c] = [(if keep? and !keep => false else true), cols]
    c = if Array.isArray c => c else [c]
    idx = @_d.h.map (h,i) -> if !(k xor (h in c)) => i else -1
    @_d.h = @_d.h.filter (h,i) -> i in idx
    @_d.b = @_d.b.map (b) -> b.filter (b,i) -> i in idx
    @

  rehead: (m) ->
    @_d.h = @_dedup @_d.h.map (h) -> m[h] or h
    @

  split: ({col}) ->
    # h: new header, m: hash of dataset for each name
    # ds: returned datasets, i: index of specified col in h
    d = JSON.parse JSON.stringify @_d # clone so we can modify it freely
    [h, m, ds] = [d.h, {}, []]
    if !~(i = h.indexOf(col)) => return @clone! # index of col
    h.splice i, 1 # col removed since we use it to split
    for b in d.b =>
      m[][b[i]].push b # row added to table named `val` from col of b (b[i])
      b.splice i, 1 # val for col removed
    for k,v of m => ds.push new datum {head: h, body: v, name: "#{if @_d.n => @_d.n + '/' else ''}#k"}
    return ds

  pivot: (o = {}) ->
    {col, join-cols, simple-head} = o
    if !(simple-head?) => simple-head = false
    ds = @split {col}
    ds = ds.map (d) -> d.shrink {cols: col, keep: false}
    ret = datum.join {ds, join-cols, simple-head} # TODO confirm if this is correct
    @from ret
    @

  join: ->
    args = Array.from(arguments)
    opt = args.filter(->it and (it.join-cols or it.ds)).0 or {}
    ds = if Array.isArray(opt.ds) => opt.ds else args
    ds = ds
      .map ->
        if it instanceof datum => return it
        else if Array.isArray(it) or it.body => return datum.from it
        else null
      .filter -> it
    if @ instanceof datum => ds = [@] ++ ds
    # TODO datasets may use different separator. we should unify them.
    sep = ds.0.sep!
    {join-cols, simple-head} = opt
    hs = ds.map -> it._d.h
    bs = ds.map -> it._d.b

    # we have multiple tables. we want to join them but some columns may have the same name.
    # so we prefix them with table names.
    # yet we are probably joining tables from the same table due to pivoting.
    # in this case table names share common part. we only need to prefix not-common part.
    ns = ds.map (d,i) -> d.name! or "#{i + 1}"
    ss = ns.map ~> it.split(sep)
    idx = -1
    for i from 0 til ss.0.length =>
      for j from 1 til ss.length =>
        if ss[j][i] != ss[0][i] =>
          idx = i
          break
      if idx >= 0 => break
    # not-common part table names
    if idx < 0 => ns = ds.map (d,i) -> "#{i + 1}"
    else ns = ss.map ~> it.slice(idx).join(sep)

    # count how many times a header name appear in all tables.
    heads = {}
    hs.map (head) -> head.map (h) -> heads[h] = (heads[h] or 0) + 1

    # join-cols is the array of columns to join.
    # if omitted, we use intersection of all headers for it.
    if !join-cols => join-cols = [k for k of hs].filter -> hs[it] == hs.length

    # rename head (h) based on table name (n) if necessary.
    rehead = (n,h) ~>
      # simple-head is true - force to not rename.
      if simple-head => return n
      # h appears multiple times. we need to prefix it to prevent collision.
      if heads[h] > 1 => return "#n#{sep}#h"
      # h only appears once. no need to prefix it.
      return h

    # head mapping.
    hm = hs.map (h,i) ->
      Object.fromEntries(
        h.map (_h) -> [_h, (if !(_h in join-cols) => rehead(ns[i],_h) else _h) ]
      )
    # all headers after joining.
    nhs = hs.map (h,i) ->
      nh = h
        .filter (_h) -> !(_h in join-cols) # common parts are already added above.
        .map (_h) -> rehead ns[i], _h      # rename h if necessary.
    head = ([join-cols] ++ nhs).reduce(((a,b) -> a ++ b),[])

    # group rows by values in join-cols
    join-values = {}
    bs.map (body,i) ->
      head = hs[i]
      body.map (b) ->
        ret = {}
        index = JSON.stringify(Object.fromEntries(
          join-cols.map (h) -> [h,b[head.indexOf(h)]]
        ))
        # rehead body based on head mapping `hm`
        # ret is the dest body while we use object instead of array
        # to make join easier. will convert it back to array later.
        for j from 0 til head.length => ret[hm[i][head[j]]] = b[j]
        join-values[][index].push ret
    body = []
    for k,list of join-values =>
      body.push list.reduce(((a,b) -> a <<< b), {})
    body = body.map (b) -> head.map (h) -> b[h]
    return datum.from {head, body, name: ds.0.name! or ''}

  unpivot: (opt = {}) ->
    {cols, name, order} = opt
    cols = if Array.isArray(cols) => cols else [cols]
    cols = @_d.h.filter -> !(it in cols)
    if !name => name = \item
    if !(order?) => order = 0
    sep = @_sep
    body = @_d.b
    hs = @_d.h
      .filter -> !(it in cols)
      .map ~> it.split(sep)
    vals = Array.from(new Set(hs.map -> it[order]))

    tables = vals.map (v) ~>
      _cols = cols.map(->[it, it])
      _hs = hs
        .filter(->it[order] == v)
        .map(->
          [
            it.join(sep),
            it.filter((d,i) -> i != order).join(sep) or \value
          ]
        )
      datum.from do
        name: @name!
        head: cols ++ [name] ++ _hs.map(->it.1)
        body: body.map (b) ~> 
          cols.map((c)~>b[@_d.h.indexOf(c)]) ++ [v] ++ _hs.map((h) ~> b[@_d.h.indexOf(h.0)])

    ret = datum.concat tables
    @_d = ret._d
    return @

  # TODO: test
  group: (opt = {}) ->
    {cols,group-func} = opt
    agg = opt.aggregator or {}
    _agg = {}
    cols = if Array.isArray(cols) => cols else [cols]
    # index of columns to merge
    hs = @_d.h
      .map (h,i) -> if !(h in cols) and (agg[h] != null) => i else -1
      .filter -> it >= 0
    # prepare aggregator for each columns to merge
    hs.map (i) ~> _agg[i] = agg[@_d.h[i]]

    # index of the index columns in head
    idxs = cols.map (c) ~> @_d.h.indexOf(c)
    # corresponding key of the index columns
    keys = Array.from(new Set(
      @_d.b.map (b) ~> JSON.stringify(Object.fromEntries(
        idxs.map (i) ~> [@_d.h[i], b[i]]
      ))
    ))

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
    body = newkeys.map (nk) ~>
      list = Array.from(hash[nk])
      nk = JSON.parse(nk)
      list = list
        .map (k) ~>
          k = JSON.parse(k)
          @_d.b.filter (b) ~> !idxs.filter((i) ~> b[i] != k[@_d.h[i]]).length
        .reduce(((a,b) -> a ++ b), [])
      ret = []
      idxs.map (i) ~> ret.push nk[@_d.h[i]]
      hs.map (h,i) ~>
        ls = list.map((l) ~> l[h])
        ret.push(if _agg[h] => _agg[h] ls else ls.length)
      ret
    @from do
      name: @_d.n
      head: (cols ++ hs.map((i) ~> @_d.h[i]))
      body: body
    return @

datum.prototype = Object.create(Object.prototype) <<< itf
datum <<<
  from: (d) -> if (d instanceof datum) => d.clone! else new datum d
  format: itf.format
  join: (o) -> (new datum!).join(o)
  concat: (ds) ->
    ds = if arguments.length > 1 => Array.from(arguments) else ds
    ds.map -> console.log it.as-sheet!
    ret = datum.from ds.0
    ret.concat.apply(ret, ds.slice 1)
    ret
  agg:
    average: -> it.reduce(((a,b) -> a + (if isNaN(+b) => 0 else +b)),0) / (it.length or 1)
    sum: -> it.reduce(((a,b) -> a + (if isNaN(+b) => 0 else +b)),0)
    count: -> it.length
    first: -> it.0 or ''

for k,v of itf =>
  if datum[k] => continue
  ((k,v) ->
    datum[k] = (d, ...args) ->
      d = if datum.format(d) == \datum => d else datum.from(d)
      v.apply d, args
  )(k,v)

if module? => module.exports = datum
else if window? => window.datum = datum
