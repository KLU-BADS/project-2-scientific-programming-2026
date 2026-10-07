# Builds the full path to a CSV file in the data folder, checks that the file exists and then reads it to Julia
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

# Load the raw source tables needed for downstream cleaning and joining.
function read_raw_data(data_folder)
    return (
        internal = read_table(data_folder, "internal_db.csv"),
        scm = read_table(data_folder, "scm_db.csv"),
        supplier_lanes = read_table(data_folder, "lm_supplier_dc.csv"), # refers to delivery from suppliers to our logistics center
        hub_lanes = read_table(data_folder, "lm_logistics_dc.csv") # referts to the delivery from an intermediary fullfillment center to our logistics center
    )
end

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
