# types, dimension and binding

## Type

To use a dataset, we need to know the types of each data column. 

    types = datum.type.get(dataset)

Data types in `@plotdb/datum` are defined as follow:

 - `R` - ratio data
 - `O` - ordered data
 - `C` - category data
 - `N` - nominal data

Additional types may be defined but should be defined with one of the above types as their fallback type. 

By default here is no information about type in dataset so `@plotdb/datum` calculate type for each column. Types are represented in probability, and the type with highest probability is used as the default type of specific column.

Type is sometimes based on semantic, e.g., we can't determine a column as ordered data if we don't know the semantic of following strings:

    'January', 'Feburary', 'March', 'April', 'May'

User should define the type and provide a proper handler for their data if possible. This mechanism isn't impelmented but could be defined and supported in the future work.


## Dimension

When we want to use a dataset ( such as in a chart ), we need to specify the types of columns we can use. This is done by defining the corresponding dimension object.

Below is a dimension object with two dimensions `height` and `name`, with the type requirement defined in the corresponding dimension requirement object:

    {
      height: {type: 'R', multiple: true, priority: 2, require: false},
      name: {type: 'N', priority: 1, require: false}
    }

A dimension requirement object contains following fields:

 - `type`: a string of all possible types (their corresponding letter), ordered by priority.
   - here are some examples of possible types: `OR`, `CN`, `N`, or `ORCN`.
 - `multiple`: default false. true if this dimension accepts multiple values and should be considered as an array.
 - `priority`: lower value means higher priority.
   - dimension with higher priority should take priority over other dimensions when binding data fields and competing for the same type fields.
 - `require`: default false. if true, this dimension is required and should always be bound with some fields before using.



## Binding

There will still be multiple possible combinations even if we already have a dataset and a dimension definition. A specific combination is called a `binding`, binding between dataset and dimension definition.

Following is a binding object which binds `income`, `spending` to `height`, and `country` to `name`.:

    {
      height: [{key: "income"}, {key: "spending"}],
      name: {key: "country"}
    }

based on dataset and dimension we can guess the best binding between them based on the types information, which can be done by `autobind`:

    binding = datum.autobind(dataset, dimension)
