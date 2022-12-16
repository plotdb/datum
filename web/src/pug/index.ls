view = new ldview { root: document.body }

ds = {}
s = {}

new-sheet = (n) -> 
  s[n] = new sheet do
    root: view.get(n)
    data: ds[n].as-sheet!
    frozen: row: 1
    fixed: row: 1

get-type = (n) ->
  ret = datum.type.get ds[n]
  db = ds[n].as-db!
  ret.map (d,i) ->
    idx = db.head.indexOf(d.key)
    c = s[n].cell x: (idx + 1), y: 1 
    c.textContent = d.type

ds.src = datum.from [
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

new-sheet \src
get-type \src

ds.pivot = datum.pivot ds.src, {col: "category", join-cols: <[year attribute]>}
console.log "[ds - after pivot]", ds.pivot

new-sheet \pivot
get-type \pivot

dimension =
  x: type: \O, priority: 1
  y: type: \R, priority: 2
  cat: type: \C, priority: 3

bind = datum.type.bind ds.pivot, dimension
console.log bind

ret = ds.pivot.split {col:\attribute}
ds.split1 = ret.0
ds.split2 = ret.1
new-sheet \split1
new-sheet \split2
get-type \split1
get-type \split2

ds.group = ds.pivot.group {cols: <[attribute]>, aggregator: {
  year: datum.agg.first
  "Online-value": datum.agg.average
  "Offline-value": datum.agg.average
}}
new-sheet \group
get-type \group

binding = 
  x: {type: \O, key: \order, offset: 1980, repeat: 3}
  c: {type: \C, key: \category, count: 3, random: false}
  n: {type: \N, key: \name}
  y: [0 to 3].map -> {type: \R, key: "sensor-#it", range: [50, 100]}
ret = datum.sample.generate {count: 100, binding}
ds.gen = new datum ret.raw
console.log ret

new-sheet \gen
get-type \gen
