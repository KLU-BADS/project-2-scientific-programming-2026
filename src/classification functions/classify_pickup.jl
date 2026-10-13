using Dates


"""
    classify_pickup(pickup_date::Date, pickup_location_id, delivery_location_id, supplier_lanes) -> Date

Estimated time of arrival (ETA) of a shipment that has not reached a hub:
the pickup date plus the transit days of the lane
`(pickup_location_id, delivery_location_id)` in `supplier_lanes`.

The caller chooses the pickup date: `classify_row` passes the actual pickup
date if it is known, otherwise the planned one. Throws a `KeyError` if the
lane does not exist.

# Examples
```julia
classify_pickup(Date(2026, 10, 1), 1, 14, supplier_lanes)   # Date(2026, 10, 25), 24 days
```
"""
function classify_pickup(
    pickup_date::Date,
    pickup_location_id,
    delivery_location_id,
    supplier_lanes
)
    travel_time = supplier_lanes[
        (pickup_location_id, delivery_location_id)
    ].day

    return pickup_date + Day(travel_time)  # Estimated time of arrival
end

