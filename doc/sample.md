# sample data

`datum.sample` provides some basic sample data for quick prototyping. It contains:

 - `C`: an array of string for category type data
 - `N`: an array of string for nominal type data
 - `generate({count, binding})`: generate a sample dataset based on the given options.
   - return `{raw, binding}` data pair where
     - `raw`: an array of objects (in the format of body of db view dataset) 
     - `binding`: the generated binding object between `raw` data and the original `binding` object.
   - and the options:
     - `count`: total number of rows to generate. default 10 if omitted.
     - `binding`: an object with each field key as the dimension name, field value as an object indicating how to generate data, with following possible fields:
       - `key`: used as the column name.
       - `name`: verbose name
       - `type`: type of data to generate. either `R`, `O`, `C` or `N`.
       - `range`: a two-value array indicating range of the generated value. applicable only for `R` type data.
       - `count`: at most how many distinct value to generate. applicable only for `C` type data.
       - `repeat`: repeat times of the generate value. applicable only for `O` type data.
         - e.g., [1,2,3,4,5] when repeat = 1 , [0,1,1,2,2] when repeat = 2, etc.
       - `offset`: offset of the generate value. applicable only for `O` type data.

