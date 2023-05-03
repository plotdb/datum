# Change Logs

## v0.1.4

 - fix bug: trim throws exception when data contains corrupted(undefined) rows


## v0.1.3

 - fix bug: unexpected null value in data after transpose. trim dataset after transpose to fix this.


## v0.1.2

 - support `transpose` api


## v0.1.1

 - support `trim` api


## v0.1.0

 - Breaking Changes: API changes.
 - Refine document
 - upgrade dev dependencies and fix dependencies vulnerabilities
 - fix bug: typo in `concat` api


## v0.0.11

 - fix bug: `bind()` for multiple dimension check types in incorrect fields


## v0.0.10

 - further minimize generated js file with mangling and compression
 - add `main` and `browser` field in `package.json`.
 - upgrade modules
 - patch test code to make it work with upgraded modules
 - remove assets files from git
 - release with compact directory structure


## v0.0.9

 - skip types without probability
 - add type `I`


## v0.0.8

 - add `type` field in dataset
 - support unit propagation in autobind.


## v0.0.7

 - support data operations for `unit` and `mag` fields.


## v0.0.6

 - provide default value of datatypes for bind
 - change group-func logic
 - fix bug: dimension binding priority inversed


## v0.0.5

 - support `ds` in `join` API for `pivot` API to use.
 - fix `pivot` by rewriting multiple dataset join with `_join-all` function


## v0.0.4

 - add `simpleHead` option in `join` and `pivot`.


## v0.0.3

 - use deconstructing assignment in API for better argument semantics.
 - add `shrink` and `rename` api.

 
## v0.0.2

 - use option object as arguments
 - support sophisticated grouping method
 - check NaN in default aggregator
 - extend db view format
