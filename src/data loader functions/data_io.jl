"""
    read_table(data_folder, filename) -> DataFrame

Read one CSV file from `data_folder`, with every column read as text.

Parsing into numbers, dates and booleans happens later, explicitly, in the
cleaning functions. Throws an `ArgumentError` naming the path if the file
does not exist.
"""
function read_table(data_folder, filename)
    # Result of joinpath() typically looks like this: "data/SCM_db.csv"
    filepath = joinpath(data_folder, filename)

    # Checks whether the file path actually contains a valid file
    if !isfile(filepath)
        throw(ArgumentError("Required data file was not found: '$filepath'"))
    end 

    # Function reads the file and sends the resulting data frame back to the calling function
    return CSV.read(filepath, DataFrame; types = String)

end

"""
    read_raw_data(data_folder) -> NamedTuple

Read the four input files and return them as
`(internal, scm, supplier_lanes, hub_lanes)`:

- `internal`: `Internal_db.csv`, the internal order items
- `scm`: `SCM_db.csv`, the shipments from the SCM system
- `supplier_lanes`: `lm_supplier_dc.csv`, transit days from the supplier to each distribution center
- `hub_lanes`: `lm_logistics_dc.csv`, remaining transit days from a hub to each distribution center
"""
function read_raw_data(data_folder)
    return (
        internal = read_table(data_folder, "Internal_db.csv"),
        scm = read_table(data_folder, "SCM_db.csv"),
        supplier_lanes = read_table(data_folder, "lm_supplier_dc.csv"), # refers to delivery from suppliers to our logistics center
        hub_lanes = read_table(data_folder, "lm_logistics_dc.csv") # referts to the delivery from an intermediary fullfillment center to our logistics center
    )
end

"""
    export_tables(joined, hub_lanes, supplier_lanes, output_folder) -> nothing

Write the cleaned data to `output_folder` (created if needed) as
`joined.csv`, `hub_lanes.csv` and `supplier_lanes.csv`, for checking the
cleaned tables by hand. Not called by `main`.
"""
function export_tables(joined, hub_lanes, supplier_lanes, output_folder)
    # Create the folder if it does not already exist.
    mkpath(output_folder)

    hub_table = lanes_to_dataframe(hub_lanes)
    supplier_table = lanes_to_dataframe(supplier_lanes)

    CSV.write(joinpath(output_folder, "joined.csv"), joined)
    CSV.write(joinpath(output_folder, "hub_lanes.csv"), hub_table)
    CSV.write(joinpath(output_folder, "supplier_lanes.csv"), supplier_table)

    return nothing
end
