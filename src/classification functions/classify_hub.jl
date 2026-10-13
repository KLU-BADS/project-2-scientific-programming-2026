using Dates

"""
    classify_hub(hub_arrival_date::Date, pickup_location_id, delivery_location_id, hub_lanes) -> Date

Estimated time of arrival (ETA) of a shipment that has reached a hub: the
hub arrival date plus the transit days of the lane
`(pickup_location_id, delivery_location_id)` in `hub_lanes`. Throws a
`KeyError` if the lane does not exist.

# Examples
```julia
classify_hub(Date(2026, 10, 5), 7, 17, hub_lanes)   # Date(2026, 10, 8), 3 days
```
"""
function classify_hub(hub_arrival_date::Date, pickup_location_id, delivery_location_id, hub_lanes)
    travel_time = hub_lanes[(pickup_location_id, delivery_location_id)].day
    return hub_arrival_date + Day(travel_time) # Estimated time of arrival
end


