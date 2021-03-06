# dataset
 
dataset is simply defined in plain json format, in following 2 representations:

## Sheet View

With sheet view, a dataset is a 2D array with the first row as sheet header. For example:

    [
      ["year", "name", "score"],
      [2020, "John", 85],
      [2021, "Mary", 79],
      [2022, "Bill", 91]
    ]

Sheet representation of dataset is usually for importing data.


## DB View

With DB ( Database ) view, dataset are separated into following parts:

 - mandatory fields:
   - `head`: an string array of column names.
   - `body`: an object array for storing data.
 - optional fields:
   - `name`: a string for dataset name. default `unnamed` if omitted.
   - `sheet`: sheet counterpart of this object.
   - `meta`: meta information. user defined.
   - `unit`: an object, mapping head names to corresponding unit.
   - `mag`: an object, mapping head names to corresponding magnitude.
   - `type`: datatype object, maaping head names to corresponding type object.
     - `type`: primary type of specific column. possible types: R, O, N, C
     - `types`: hash of probability ( 0 ~ 1 ) and type mapping.



For example:

    {
      name: "Sample data",
      head: ["year", "name", "score"],
      body: [
        {"year": 2020, "name": "John", "score": 85},
        {"year": 2021, "name": "Mary", "score": 79},
        {"year": 2022, "name": "Bill", "score": 91}
      ]
    }

All operations in `@plotdb/datum` use db view by default.


## Dataset operations

`@plotdb/datum` provides following basic operations to manipulate dataset.


### Dataset Types

 - `format(ds)` - retrun `db` if ds is in db view, else return `sheet`.
 - `asDb(ds, name)` - convert ds into db view. If it's already in db view, return ds directly.
   - `name`: optional dataset name to use if there is no information about ds's name. `unnamed` if omitted.
 - `asSheet(ds)` - convert ds into sheet view. If it's already in sheet view, return ds directly.

convert between sheet and db view:

    var db = datum.asDb(dataset);
    var sheet = datum.asSheet(dataset);


### Sheet Manipulation

 - `concat(datasets)` - concat datasets in given order.
 - `join({ds, d1, d2, joinCols, simpleHead})` - join datasets based on configurations.
   - `ds`: array of datasets to join. when `ds` provided, `d1` and `d2` are ignored.
   - `d1`: dataset to be joined. exclusive with `ds`
   - `d2`: dataset to join. exclusive with `ds`.
   - `joinCols`: array of name of column used to join.
   - `simpleHead`: true to not keep original column name when resolving collision. default false.
 - `unjoin({data, cols])` - unjoin ( TODO )
 - `split({data, col})` - split dataset by col value.
 - `pivot({data, col, joinCols, simpleHead})` - pivot based on `col` column ( split based on `col`, then join based on `joinCols` )
    - `data`: dataset to pivot
    - `col`: name of the column to pivot. 
    - `joinCols`: array of name of columns to join after table spliting based on `col`.
    - `simpleHead`: true to remove original column head name. default false.
 - `unpivot({data, cols, name, order})` - unpivot
   - `data`: dataset to unpivot
   - `cols`: columns to stay ( not involved in unpivot )
   - `name`: name of the new column created after unpivoted
   - `order`: default 0. which part in column name to use 
     - names of the column to unpivot are generated by `pivot` and contains name of the columns before pivot.
     - yet there may be multiple pivot involved. so we have to decide which name to use.
 - `group({data, cols, aggregator, groupFunc})` - merge some rows into one.
   - `data`: dataset to group
   - `cols`: index columns. rows with the same value in these columns with be merged into one row.
   - `aggregator`: hash of column name to a aggregating function. default to count of rows to merge.
   - `group-func`: either a function, or an object of column name to a mapping function of values in the column
     - a function: take each row as input, return a group key for grouping rows.
       - to assign multiple groups for one row, simply return an array of group keys.
     - an object: containing value transform function for each column
       - use identity function when a function for certain column is omitted.
     - useful to group different values into one. e.g., this function groups values by tens digit:
       `-> Math.floor(it / 10)`
 - `rename({data, map})`: rename columns.
   - `data`: dataset to rename its columns.
   - `map`: hash of map from current column name to new column name. keep old name if such mapping is not found.
 - `shrink({data, cols})`: remove some columns from dataset.
   - `data`: dataset to shrink
   - `cols`: array of column names to keep.
 - `agg`: this is an object containing following default aggregating functions:
   - `average(list)`: return average value of the given list
   - `sum(list)`: return summation of the given list
   - `count(list)`: return entry count of the given list
   - `first(list)`: return first entry of the given list


#### group

Predefined aggregate functions are available in `datum.agg`:

 - `average`
 - `sum`
 - `count`
 - `first`

datum.group(dataset, "year", {
  "score": datum.agg.average,
  "rank": datum.agg.count,
  "ppl": datum.agg.sum,
});

when columns are omitted, by default `datum` uses `datum.agg.count`. Or, to discard unwanted columns, simly use `null`.

