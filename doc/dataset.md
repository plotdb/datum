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

 - name: a string for dataset name
 - head: an string array of column names.
 - body: an object array for storing data.

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
 - `join(dataset1, dataset2, jc)` - join 2 datasets based on the jc provided.
 - `unjoin(dataset, cols)` - unjoin ( TODO )
 - `split(dataset, col)` - split dataset by col value.
 - `pivot(dataset, col, jc)` - pivot
 - `unpivot(dataset, cols, name, order)` - unpivot
 - `group(dataset, col, agg)` - group by col with aggregate functions stored in `agg` hash.


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

