# dataset
 
Dataset is a set of data. It contains multiple rows with different columns in each row, such as:

    [{name: 'John', score: 95}, {name: 'Mary', score: 79}, ...]

Dataset can be simply defined with a plain json format in either `sheet` or `db` view, described below. 


### Sheet View

With sheet view, a dataset is a 2D array with the first row as sheet header. For example:

    [
      ["year", "name", "score"],
      [2020, "John", 85],
      [2021, "Mary", 79],
      [2022, "Bill", 91]
    ]

Sheet view of a dataset is usually for import/exporting of a dataset, especially from a spreadsheet program.


### DB View

With DB ( Database ) view, a dataset is an object with following fields:

 - mandatory fields:
   - `head`: an string array of column names.
   - `body`: an object array for storing data.
 - optional fields:
   - `name`: a string for dataset name. default `unnamed` if omitted.
 - TBD fields:
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



## Dataset Object

In `@plotdb/datum`, a dataset is represented with an instancea of `datum` object. Datasets can be manipulated via `datum`'s API or class methods, which is described as below.


### Constructor Options

To create a `datum` object:

    var ds = new datum(opt)

where the constructor options `opt` can be a dataset JSON object or another `datum`:

    new datum({body: ..., head: ...});
    new data([['name', 'score'], ['John', 87], ['Mary', 76], ...]);


or, an option object with following fields:

 - `sep`: separator of column names when pivoting
 - `data`: a optional dataset to initialize this object.


### APIs

General APIs:

 - `clear()`: clear data, making this `datum` an empty object.
 - `clone()`: duplicate this as a new object.
 - `format(o)`: determine and return the type of the given object `o`, which is a string of either:
   - `db`: an (array of) object.
   - `datum`: it's a `datum` object.
   - `sheet`: a spreadsheet-like 2D array.
 - `from(d)`: construct a `datum` object from the given `d`.
 - `asSheet()`: return a sheet-style 2D array from this object.
 - `asDb()`: return an object with `name`, `head` and `body` field.
 - `name()`: return name of this object.
 - `head()`: return column names (head) of this object.
 - `body()`: return data (body) of this object.
 - `sep(s)`: if `s` is provided, set it as the separator of this object. otherwise return the current separator.


Data Manipulation APIs:

 - `rehead(m)`: map current column names to new names based on `m`:
   - return this object.
   - `m`: a hash which maps old names to new names.
     - names without mapping won't be updated.
 - `concat(d1, d2, ...)`: concating the given parameters into this object. (append as new rows)
   - return this object.
   - `d1`, `d2`, ...: data objects (either sheet, db or `datum` object)
 - `shrink({cols, keep})`: shrink this object by removing some columns.
   - return this object.
   - options:
     - `keep`: default true. when true, `cols` option list the columns to keep, otherwise the columns to remove.
     - `cols`: array of column names to keep or remove, based on `keep` option.
 - `split({col})`: split this object based on the given column `col`.
   - return a list of new `datum` objects splitted from this object.
     - names of the new `datum` objects will be:

           <original name>/<column value>

   - options:
     - `col`: name of the column to split.
       rows with the same column value will be aggregated into one object.
 - `pivot(o)`: pivot transformation ( converting rows to columns ).
   - return this object.
   - options:
     - `col` and `joinCols`:
       - `pivot` involves in 2 steps: split and join,
         so we need `col` option (a string) for splitting, and the `joinCols` (array of strings)  for joining.
     - `simpleHead`: true to remove original column head name. default false.
 - `join(o)`: join multiple dataset in the given parameters into this object. (append as new cols)
   - options:
     - `ds`: array of dataset.
     - `joinCols`: array of name of column used to join.
     - `simpleHead`: true to not keep original column name when resolving collision. default false.
   - alternatively, multiple parameters can be provided for datasets and parameters.
     In this case, all parameters will be treated as dataset, except the parameter with `joinCols` field.
 - `unjoin({cols})` - unjoin ( TODO )
 - `unpivot({cols, name, order})` - unpivot
   - `cols`: columns to unpivot ~~columns to stay ( not involved in unpivot )~~
   - `name`: name of the new column created after unpivoted
   - `order`: default 0. which part in column name to use 
     - names of the column to unpivot are generated by `pivot` and contains name of the columns before pivot.
     - yet there may be multiple pivot involved. so we have to decide which name to use.
 - `group({cols, aggregator, groupFunc})` - merge some rows into one.
   - `cols`: index columns. rows with the same value in these columns with be merged into one row.
   - `aggregator`: hash of column name to a aggregating function. default to count of rows to merge.
   - `group-func`: decide what values should be considered as the same ( i.e., the same group )
     - either a function, or an object of column name to a mapping function of values in the column
       - a function: take each row as input, return a group key for grouping rows.
         - to assign multiple groups for one row, simply return an array of group keys.
       - an object: containing value transform function for each column
         - use identity function when a function for certain column is omitted.
       - useful to group different values into one. e.g., this function groups values by tens digit:
         `-> Math.floor(it / 10)`
 - `trim()` - clear up dataset by removing empty rows and columns
   - `""`, `undefined` and `null` will be considered as empty.
   - only rows / columns containing only empty values will be removed.
 - `transpose()` - transpose dataset, like a sheet.

`datum` class itself also provides above methods, so this is possible:

    datum.as-sheet(dataset)

In this kind of usage, the first argument should be a dataset.


### Grouping

`datum.agg` provides following aggregator for grouping:

 - `average`: grouping values with their average.
 - `sum`: grouping values with their sum.
 - `count`: grouping values with the amount of grouped rows.
 - `first`: use the very first value as the grouping result.

A sample usage:

    ds.group("year", {
      "score": datum.agg.average,
      "rank": datum.agg.count,
      "ppl": datum.agg.sum,
    });

    datum.agg.average([1, 2, 3, 4, 5, ...]);

when columns are omitted, by default `datum` uses `datum.agg.count`. Or, to discard unwanted columns, simly use `null`.

