"""
    location_ids :: Dict{String, Int}

Numeric ID for every known location, keyed by its cleaned name: 13 pickup
cities (`"shanghai"` = 1 … `"hamburg"` = 13) and 4 distribution centers
(`"hamburg dc"` = 14, `"boeblingen dc"` = 15, `"herrsching dc"` = 16,
`"leipzig dc"` = 17).
"""
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

"""
    location_id(value, location_ids) -> Union{Int, Missing}

Look up the numeric ID of a location name.

The name is normalized with `clean_location` first, so spelling and
whitespace variants match. Returns `missing` for a missing name and throws
an error for a name that is not in `location_ids`, instead of guessing.

# Examples
```julia
location_id("Antwerpen", location_ids)   # 8
```
"""
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
        error("Unknown location: '$value'")
    end 

    # Return the numeric ID associated with the cleaned location name.
    return location_ids[name]
end 


"""
    add_location_ids!(shipments, location_ids) -> shipments

Add the columns `pickup_location_id` and `delivery_location_id` to a
shipment table, changing it in place.

Each row's `pickup_city` and `delivery_city` are converted with
`location_id`; a missing city gives a missing ID.
"""
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
