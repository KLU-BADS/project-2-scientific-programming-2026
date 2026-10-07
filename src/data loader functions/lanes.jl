
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