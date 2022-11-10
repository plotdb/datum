datum = require "../src/index"

new datum!
new datum []
new datum [[]]
new datum {head: [], body: []}
new datum {head: ['a','b'], body: []}
sample = {head: ['a','b'], body: [{a: 1, b: 2}, {a: 3, b: 4}]}
sample2 = {head: ['a','b','c'], body: [{a: 1, b: 2, c: 1}, {a: -3, b: -4, c: 2}, {a: 3, b: 2, c: 1}]}
d = new datum sample
console.log d.as-db!
console.log d.as-sheet!
console.log datum.from(d.as-sheet!).as-db!
console.log datum.from(d.as-db!).as-sheet!

ret = datum.from sample
  .concat datum.from(sample)
  .as-sheet!
console.log ret

ret = datum.from sample
  .shrink {cols: <[a]>}
  .as-sheet!
console.log ret

ret = datum.from sample
  .shrink {cols: <[a]>, keep: false}
  .as-sheet!
console.log ret

ret = datum.from sample2
  .split {col: \c}
  .map -> it.as-sheet!
console.log "split: ", ret

ret = datum.from sample2
  .rehead {a: \C, b: \c}
  .as-sheet!
console.log ret

sample3 = [
  <[K N]>
  <[1 John]>
  <[2 Steve]>
  <[3 Mary]>
  <[4 Toby]>
  <[5 Maggie]>
]
sample4 = [
  <[K T]>
  <[1 Pro]>
  <[2 Free]>
  <[3 Free]>
  <[4 Pro]>
  <[5 Free]>
]
ret = datum
  .from sample3
  .join sample4, {join-cols: <[K]>}
  .as-sheet!
console.log "join test: ", ret

sample5 = [
  <[Y    C V]>
  <[1990 A 1]>
  <[1990 B 2]>
  <[1991 A 3]>
  <[1991 B 4]>
  <[1992 A 5]>
  <[1992 B 6]>
]

ret = datum.from(sample5)
  .pivot {col: \C, join-cols: <[Y]>}
  .as-sheet!
console.log ret

ret = datum.from(ret)
  .unpivot {cols: <[Y]>, name: '', order: 0}
  .as-sheet!
console.log ret

sample6 = [
  <[Y    Z A B C D]>
  <[1990 IN 1 2 3 4]>
  <[1990 OUT 1 2 3 4]>
  <[1991 IN 1 2 3 4]>
  <[1991 OUT 1 2 3 4]>
  <[1992 IN 1 2 3 4]>
  <[1992 OUT 1 2 3 4]>
]

ret = datum.from(sample6)
  .unpivot {cols: <[Y Z]>, name: '', order: 0}
  .as-sheet!
console.log ret

ret = datum.from(sample6)
  .unpivot {cols: <[A B C D]>, name: '', order: 0}
  .pivot {col: \item, join-cols: <[Y Z]>}
  .unpivot {cols: <[A-value B-value C-value D-value]>, name: '', order: 0}
  .as-sheet!
console.log ret

ret = datum.from(sample6)
  .group { cols: <[Y]> }
  .as-sheet!
console.log ret
  
