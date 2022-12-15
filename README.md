# @plotdb/datum

Data manipulation library.

To manipulate data, we have following concepts:

 - `dataset` - set of data in specific format.
 - `type` - data type of a dataset column.
 - `dimension definition` - defining what is needed (such as data type) for certain purpose.
 - `binding` - define the binding between dataset and dimension.

For `dataset`, see `doc/dataset.md` for more information. For the reset ( type, dimension and binding ), see `binding.md` for more information.


## Installation

Install via npm:

    npm install --save @plotdb/datum


and include the js file:

    <script src="path/to/datum/index.min.js"></script>


Create a `datum` object:

    var d = new datum( ... );


## License

MIT
