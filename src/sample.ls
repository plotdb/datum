datum.sample =
  C: <[
    books business education entertainment finance food games
    health lifestyle medical music navigation news photography
    productivity social network sports travel utilities weather
  ]>
  N: [
    "The Perfect Storm", "Philadelphia Story", "Planet of the Apes",
    "Patton", "Pocahontas", "Pinoccio", "Quills", "Raiders of the Lost Ark",
    "Romeo and Juliet", "Snow White", "Shine", "Some Like It Hot",
    "Stardust", "Startrek", "The Seven Year Itch", "The Sound of Music",
    "Sabrina", "Sixth Sense", "The Silence of the Lambs", "Stargate",
    "Sunset Boulevard", "Superman"
  ]

  generate: ({count, binding}) ->
    [gen, idx, count] = [{raw: [], binding: {}}, 0, count or 10]
    if !fields => fields = {}
    for k,v of binding
      u = if Array.isArray(v) => v else [v]
      keys = u.map (d,i) -> 
        key = d.key or "field-#idx"
        name = d.name or key
        fields[idx] = {key, name, hint: d}
        idx := idx + 1
        idx - 1
      if Array.isArray(v) => gen.binding[k] = keys.map -> fields[it]{key, name}
      else gen.binding[k] = fields[keys.0]{key, name}
    offset = Math.round(100 * Math.random!)
    for i from 0 til count =>
      ret = {}
      for k,v of fields =>
        hint = v.hint
        value = switch hint.type
        | \R
          range = hint.range or [0,100]
          val = (Math.random! * (range.1 - range.0) + range.0)
          if range.1 - range.0 < 1 => val else Math.round(val)
        | \N => datum.sample.N[i % datum.sample.N.length]
        | \C =>
          mod = (if hint.count? => hint.count else Math.round(count / 10) >? 4) <? datum.sample.C.length
          datum.sample.C[(if hint.random => Math.floor(Math.random! * count) else i) % mod]
        | \O =>
          Math.floor(i / (if hint.repeat? => hint.repeat else 1)) + (if hint.offset? => hint.offset else offset)
        | otherwise => "..."
        ret[v.key] = value
      gen.raw.push ret
    return gen
