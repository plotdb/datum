ds = datum.as-db [
  ["year", "category", "attribute", "value"],
  [2000, "Online", "revenue", 90],
  [2000, "Offline", "revenue", 100],
  [2000, "Online", "cost", 80],
  [2000, "Offline", "cost", 70],
  [2001, "Online", "revenue", 100],
  [2001, "Offline", "revenue", 115],
  [2001, "Online", "cost", 85],
  [2001, "Offline", "cost", 76],
  [2002, "Online", "revenue", 105],
  [2002, "Offline", "revenue", 122],
  [2002, "Online", "cost", 86],
  [2002, "Offline", "cost", 72],
  [2003, "Online", "revenue", 135],
  [2003, "Offline", "revenue", 115],
  [2003, "Online", "cost", 90],
  [2003, "Offline", "cost", 65],
]
s = new sheet do
  root: ld$.find('.root',0)
  data: datum.as-sheet ds
  frozen: row: 1
  fixed: row: 1

ds2 = datum.pivot {data: ds, col: "category", join-cols: <[year attribute]>}
console.log ds2

ret = datum.type.get ds
console.log ret
ret.map (d,i) ->
  idx = ds.head.indexOf(d.key)
  c = s.cell x: (idx + 1), y: 1 
  c.textContent = d.type

dimension =
  x: type: \O, priority: 1
  y: type: \R, priority: 2
  cat: type: \C, priority: 3
bind = datum.type.bind ds2, dimension
console.log bind

s.data datum.as-sheet ds2

binding = 
  x: {type: \O, key: \order, offset: 1980, repeat: 3}
  c: {type: \C, key: \category, count: 3, random: false}
  n: {type: \N, key: \name}
  y: [0 to 3].map -> {type: \R, key: "sensor-#it", range: [50, 100]}
ret = datum.sample.generate {count: 100, binding}
ds3 = datum.as-db ret.raw
console.log ret
s.data datum.as-sheet ds3
ret = datum.type.get ds3
console.log ret
ret.map (d,i) ->
  idx = ds3.head.indexOf(d.key)
  c = s.cell x: (idx + 1), y: 1 
  c.textContent = d.type
