# Initializing location id's based on the city names
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

#= 
Map a shipment location to its  numeric ID after normalizing the input
(for example, trimming whitespace and standardizing casing), returning missing
for missing values and raising an error if the cleaned location does not exist
in the known location lookup table.
=#

function location_id(value, location_ids)
    # Normalize the location name so spelling and whitespace variations match.
    name = clean_location(value)

    # Preserve missing input instead of trying to look it up.
    if ismissing(name)
        return missing
    end 

    # Fail early if the cleaned name is not present in the ID mapping. 
    # haskey(collection,key) returns true if the collection conatins a key and flase if otherwise
    # Here has key is negated and returns true if the location id is not present in the dictionary
    if !haskey(location_ids, name)
        error("Unknwon location: '$value'")
    end 

    # Return the numeric ID associated with the cleaned location name.
    return location_ids[name]
end 


#=
Add normalized pickup and delivery location ID columns to a shipment table by
converting each row's city names through the location lookup and storing the
resulting integer IDs in separate vectors for later insertion into the DataFrame.
=#
function add_location_ids!(shipments, location_ids)
    # Union specifies the element type, meaning the value that the vector accepts. It either accepts missing values or integers 
    pickup_ids = Union{Missing, Int}[] 
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