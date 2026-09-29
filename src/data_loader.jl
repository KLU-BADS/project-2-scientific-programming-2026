using CSV 
using DataFrames
using Dates

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

function read_raw_data(data_folder)
    return (
        internal = read_table(data_folder, "internal_db.csv"),
        scm = read_table(data_folder, "scm_db.csv"),
        supplier_lanes = read_table(data_folder, "lm_supplier_dc.csv"), # refers to delivery from suppliers to our logistics center
        hub_lanes = read_table(data_folder, "lm_logistics_dc.csv") # referts to the delivery from an intermediary fullfillment center to our logistics center
    )
end

function convert_column!(table, column, converter)
    converted = map(enumerate(table[!, column])) do (row, value)
        try
            converter(value)
        # If there is an error catch err will saves in and sprint turns it into a text. Error then throws a new error and adds the column and row context
        catch err
            detail = sprint(showerror, err)
            error("Column '$column', data row '$row': '$detail'")
        end
    end

    table[!, column] = converted
    return table
end

function parse_lane_days(value)
    # Remove all whitespaces preceeding and superceeding the cell value 
    text = strip(value)

    # If cells don't contain a value they will be turned into a missing value 
    if isempty(text)
        return missing 
    end

    days = tryparse(Int, text) # if values couldn't be turned into an integer value they Julia will insert "nothing" 
    
    if days == nothing 
        throw(ValueError("Expected a whole number of days, but found: '$value'"))
    end 

    if days < 0 
        throw(ValueError("Lane duration must not be negative '$days'"))
    end 

    return days
end 

function clean_location(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end 

    normalized = lowercase(text)

    # Replacing repeated whitespaces with a single one 
    words = split(normalized)
    normalized = join(words, " ")

    # Check whether the provided city identifies as the destination 
    is_dc = endswith(normalized, " dc")

    if is_dc 
        # chop removes the last characters of a string, here further specified to fully remove " dc" 
        city = chop(normalized, tail=3)
    else 
        city = normalized 
    end 
    
    # Typical spelling variations and their standard english names 
    aliases = Dict(
        "böblingen" => "boeblingen",
        "boblingen" => "boeblingen",
        "singapur" => "singapore",
        "antwerpen" => "antwerp",
        "anvers" => "antwerp",
        "mailand" => "milan",
        "milano" => "milan",
        "warschau" => "warsaw",
        "warszawa" => "warsaw"
    )
    
    # Haskey: Determine whether a collection has a mapping for a given key
    if haskey(aliases, city)
        city = aliases[city]
    end 

    # Append " dc" after city normalization 
    if is_dc 
        return city * " dc"
    else 
        return city
    end 
end 

location_ids = Dict(
    "shanghai" => 1,
    "shenzhen" => 2,
    "singapore" => 3,
    "chicago" => 4,
    "los angeles" => 5,
    "miami" => 6,
    "rotterdam" => 7,
    "antwerp" => 8,
    "milan" => 9,
    "warsaw" => 10,
    "bratislava" => 11,
    "lyon" => 12,
    "hamburg" => 13,
    "hamburg dc" => 14,
    "boeblingen dc" => 15,
    "herrsching dc" => 16,
    "leipzig dc" => 17
)

function location_id(value, location_ids)
    name = clean_location(value)

    if ismissing(name)
        return missing
    end 

    if !haskey(location_ids, name)
        error("Unknwon location: '$value'")
    end 

    return location_ids[name]
end 

        
function clean_lane_matrix(table)
    # Cleaning the origing city which are stated in the first column first using the clean_location function 
    origin_column = names(table)[1]
    convert_column!(table, origin_column, clean_location)

    #= Cleaning the destination names which are stated in the first row, 
    while removing the first column which just contains "origin city/ distribution center" =#
    destination_columns = names(table)[2:end]

    for column in destination_columns
        # Convert column by column to an integer value
        convert_column!(table, column, parse_lane_days)

        # Cleaning the column names and checking for possible spelling issues
        cleaned_name = clean_location(column)

        if cleaned_name != column 
            rename!(table, column => cleaned_name)
        end 
    end 
    return table 
end 

struct Lane
    origin_id::Int
    destination_id::Int
    day::Int
end 

# Converts the origin and destination names into numeric IDs using location_id()
function build_lane_lookup(matrix, location_ids)
    lanes = Dict{Tuple{Int, Int}, Lane}()

    origin_column = names(matrix)[1]
    destination_columns = names(matrix)[2:end]

    for row in eachrow(matrix)
        # Using the location id function to look up the origin city id 
        origin = location_id(row[origin_column], location_ids)

       if ismissing(origin)
            error("A lane matrix row is lacking an origin")
       end

        for destination_name in destination_columns
            destination = location_id(destination_name, location_ids)

            if ismissing(destination)
                error("A lane matrix row is lacking a destination")
            end 

            days = row[destination_name]
            
            if ismissing(days)
                error("A lane matrix row lacks days")
            end 

            key = (origin, destination)

            lanes[key] = Lane(origin, destination, days) # calling the struct and initialize the previously defined dictionary
        end 
    end 
    
    return lanes
end 

        

#Trim surrounding whitespace and return missing for missing or empty values.
function clean_text(value)
    #its necessary to check whether the input is already missing as the subsequent strip function will fail otherwise
    if ismissing(value) 
        return missing 
    end
  
    text = strip(value)

    if isempty(text)
        return missing 
    else 
        return String(text)
    end 
end

function parse_delivery_date(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end

    # Example:
    # "2026-09-29 00:00:00" becomes ["2026-09-29", "00:00:00"]
    parts = split(text)
    date_text = parts[1]

    # European format: day.month.year
    if occursin(r"^\d{1,2}\.\d{1,2}\.\d{4}$", date_text)
        return Date(date_text, dateformat"dd.mm.yyyy")

    # ISO format: year-month-day
    elseif occursin(r"^\d{4}-\d{2}-\d{2}$", date_text)
        return Date(date_text, dateformat"yyyy-mm-dd")

    else
        throw(ArgumentError(
            "Expected a date such as 27.09.2026 or 2026-09-27, " *
            "optionally followed by a space and time; found '$text'"
        ))
    end
end

function parse_quantity(value)
    text = clean_text(value)
    if ismissing(text)
        return missing 
    end 

    #allows patterns like 1234; -12; +12, 1,234.5; 1,234,567; 89 and rejects everything else 
    pattern = r"^[+-]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$"

    if !occursin(pattern, text)
        throw(ArgumentError(
            "Expected an American float pattern such as 1,234.50, found '$text' instead"
            ))
    end 

    normalized = replace(text, "," => "")
    normalized = replace(normalized, "." => "")

    return parse(Float64, normalized)
end 

function parse_active(value)
    text = clean_text(value)
    
    if ismissing(text)
        return missing
    end 

    normalized = lowercase(text)

    if normalized == "yes"
        return true
    elseif normalized == "no"
        return false 
    else 
        throw(ArgumentError(
            "Expected a value of yes or no, found '$normalized'"
        ))
    end
end 

# A helper functions that checks whether the column and row conversions are successful 
#= converter refers to the function used to clean the provided column
    map(function applied to the data provided, data collection)
=#
function clean_lowercase(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end

    return lowercase(text)
end


function clean_internal(raw_table)
    table = select(
        raw_table,
        "Active" => :active,
        "Business Unit" => :business_unit,
        "Material" => :material,
        "Item Code" => :item_code,
        "Quantity" => :quantity,
        "Project ID" => :project_id,
        "k EUR" => :k_eur,
        "RDD" => :requested_delivery_date,
        "CDD" => :actual_delivery_date 
    )

    #= Calls the function clean_text and checks whether the transformation was successful, we are just using this function to  
    also strip out values, remember all values are intially strings and are then turned into the respective data format 
        =#    
    for column in names(table)
        convert_column!(table, column, clean_text)
    end 

    # Converting all columns that should not remain a string
    convert_column!(table, :active, parse_active)
    for column in (:quantity, :k_eur)
        convert_column!(table, column, parse_quantity)
    end 

    # Calling the date formatting function 
    for column in (:requested_delivery_date, :actual_delivery_date)
        convert_column!(table, column, parse_delivery_date)
    end 

    return table
end 

function clean_scm(raw_table)
    table = select(
        raw_table,
        "Project ID MP1 Reference" => :scm_project_id,
        "Shipment ID" => :shipment_id,
        "Sub shipment, delivery line, product code" => :product_code,
        "Pickup city" => :pickup_city,
        "Pickup country" => :pickup_country,
        "Delivery city" => :delivery_city,
        "Delivery country" => :delivery_country,
        "Leg 1, Pickup Planned (date)" => :pickup_planned_date,
        "Leg 1, Pickup Actual (date)" => :pickup_actual_date,
        "Leg 1, Hub Arrival (date)" => :hub_arrival_date,
        "Leg n, Delivery Actual (date)" => :scm_actual_delivery_date,
        "Leg n, Transport Mode" => :transport_mode,
        "Leg 1, Carrier Name" => :carrier_name
    )

    #= Calls the function clean_text and checks whether the transformation was successful, we are just using this function to  
    also strip out values, remember all values are intially strings and are then turned into the respective data format 
        =#    
    for column in names(table)
        convert_column!(table, column, clean_text)
    end

     # Converting all columns that should not remain a string
    for column in (:pickup_city, :delivery_city)
        convert_column!(table, column, clean_location)
    end
   
    for column in (:pickup_country, :delivery_country, :transport_mode)
        convert_column!(table, column, clean_lowercase)
    end

     # Calling the date formatting function 
    date_columns = (
        :pickup_planned_date,
        :pickup_actual_date,
        :hub_arrival_date,
        :scm_actual_delivery_date
    )

    for column in date_columns
        convert_column!(table, column, parse_delivery_date)
    end

    return table
end

function add_location_ids!(shipments, location_ids)
    pickup_ids = Union{Missing, Int}[] #the vector accepts either missing values or integers 
    delivery_ids = Union{Missing, Int}[]

    #Converting the city names into ids and saving them in the respective vector 
    for row in eachrow(shipments)
        pickup = location_id(row.pickup_city, location_ids)

        delivery = location_id(row.delivery_city, location_ids)

        push!(pickup_ids, pickup)
        push!(delivery_ids, delivery)
    end 

    # Adding two new columns to the data frame and selecting the respective vector that should be inserted in the columns 
    shipments[!, :pickup_location_id] = pickup_ids
    shipments[!, :delivery_location_id] = delivery_ids

    return shipments
end 






#= @__DIR__ is commonly used to derive the current folder file directory, 
the two dots simply mean that we move up one directory from src to the project root,
normpath removes the two dots and normalize the file directory=#
data_folder = normpath(joinpath(@__DIR__, "..", "data"))
raw = read_raw_data(data_folder) #creates a named tuple 

supplier_lanes_clean = clean_lane_matrix(raw.supplier_lanes)
hub_lanes_clean = clean_lane_matrix(raw.hub_lanes)

supplier_lanes = build_lane_lookup(
    supplier_lanes_clean,
    location_ids
)

hub_lanes = build_lane_lookup(
    hub_lanes_clean,
    location_ids
)

internal = clean_internal(raw.internal)
scm = clean_scm(raw.scm)
joined = leftjoin(
    internal,
    scm;
    on = :item_code => :product_code,
    matchmissing = :error
)

add_location_ids!(joined, location_ids)



function lanes_to_dataframe(lane)
    table = DataFrame(
        origin_id = Int[],
        destination_id = Int[],
        day = Int[]
    )

    for lane in values(lane)
        push!(table, (
            origin_id = lane.origin_id,
            destination_id = lane.destination_id,
            day = lane.day
        ))
    end

    sort!(table, [:origin_id, :destination_id])
    return table
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

output_folder = joinpath(@__DIR__, "..", "outputs")

export_tables(joined, hub_lanes, supplier_lanes, output_folder) 