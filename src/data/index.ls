rand-fname = -> return "..."
generate = (count, binding) ->
  gen = do
    raw: []
    binding: {}
  fields = {}
  idx = 0
  for k,v of binding
    u = if Array.isArray(v) => v else [v]
    keys = u.map -> 
      fields[idx] = {key: rand-fname!, hint: it}
      idx++
    if Array.isArray(v) => gen.binding[k] = keys.map -> fields[it]{key}
    else gen.binding[k] = fields[keys.0]{key}

  for i from 0 til count =>
    for k,v of fields =>
      ret = {}
      hint = v.hint
      name = v.key
      value = "..."
      switch hint.type
      | \R
        range = hint.range or [0,1]
        value = Math.round(Math.random! * (range.1 - range.0) + range.0)
      | \N
        value = <[A B C D E]>[Math.floor(Math.random! * 5)]
      ret[v.key] = value
    gen.raw.push ret
  return gen

generate 10, do
  height: [0 to 3].map -> {type: \R, range: [0, 10]}
  name: {type: \N}
