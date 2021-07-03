# types, dimension and binding

## Type

To use a dataset, we need to know the types of each data column. 

types = datum.type(dataset)

Data types in `@plotdb/datum` are defined as follow:

 - `R` - ratio data
 - `O` - ordered data
 - `C` - category data
 - `N` - nominal data

By default here is no information about type in dataset so `@plotdb/datum` can calculate type for each column. Types are represented in probability, and the type with highest probability is used as the default type of specific column.

Type is sometimes based on semantic, e.g., we can't determine a column as ordered data if we don't know the semantic of following strings:

    'January', 'Feburary', 'March', 'April', 'May'

(TBD/TODO) this can be extended by providing a sample array with string in context placed in their semantic order.

## Dimension

When we want to use dataset ( such as charting ), we may need to specify the types of columns we can use. 

    {
      height: {type: 'R', multiple: true, priority: 2, require: false},
      name: {type: 'N', priority: 1, require: false}
    }


## Binding

Even if we have types of dataset's column and have the what we need defined in dimension, we still need to map from dataset's column to dimension.

    {
      height: [{key: "income"}, {key: "spending"}],
      name: {key: "country"}
    }

based on dataset and dimension we can guess the best binding between them based on the types information, which can be done by `autobind`:

    binding = datum.autobind(dataset, dimension)
