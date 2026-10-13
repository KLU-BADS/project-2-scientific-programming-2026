"""
    Lane(origin_id, destination_id, day)

One lane of a lane matrix: the transit time `day` (in days) from the
location `origin_id` to the distribution center `destination_id`.
"""
struct Lane
    origin_id::Int
    destination_id::Int
    day::Int
end 

"""
    build_lane_lookup(matrix, location_ids) -> Dict{Tuple{Int, Int}, Lane}

Turn a cleaned lane matrix into a lookup keyed by
`(origin ID, destination ID)`.

Every origin row and destination column becomes one `Lane`; names are
converted with `location_id`. Throws an error if an origin, destination or
day value is missing. With the current data, each lane file gives
13 × 4 = 52 lanes.

# Examples
```julia
hub_lanes[(7, 17)].day   # 3 (Rotterdam → Leipzig DC)
```
"""
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

"""
    lanes_to_dataframe(lane) -> DataFrame

Turn a lane lookup back into a table with the columns `origin_id`,
`destination_id` and `day`, sorted by origin and destination. Used by
`export_tables`.
"""
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
