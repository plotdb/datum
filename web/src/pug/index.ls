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

ds2 = datum.pivot ds, "category", <[year attribute]>
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
