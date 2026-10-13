# Reference manual

Every function of `Project2`, grouped by component in the order the program
uses them: the Data Loader reads and cleans the input files, Classification
decides the stage, ETA and status of each item, Output builds the report, and
the main pipeline runs all of it.

```@autodocs
Modules = [Project2]
Pages = ["Project2.jl"]
```

## Data Loader

Reading the four CSV files, cleaning and typing their columns, mapping
locations to IDs and building the lane lookups.

```@autodocs
Modules = [Project2]
Pages = ["text_cleaning.jl", "value_parser.jl", "table_cleaning.jl", "locations.jl", "lanes.jl", "data_io.jl"]
```

## Classification

Tracking stage, estimated time of arrival and delivery status of one item.

```@autodocs
Modules = [Project2]
Pages = ["determine_tracking_status.jl", "classify_delivered.jl", "classify_hub.jl", "classify_pickup.jl", "shipment_delivery_status.jl"]
```

## Output

Severity, icons, the report table and the CSV export.

```@autodocs
Modules = [Project2]
Pages = ["output_creation.jl"]
```

## Main pipeline

Settings, status codes and the functions that run the program from start
to end.

```@autodocs
Modules = [Project2]
Pages = ["main.jl"]
```
