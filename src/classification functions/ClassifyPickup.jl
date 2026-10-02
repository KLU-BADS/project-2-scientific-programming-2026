using Dates

# Uses pickup_date, pickup_location_id and delivery_location_id
# and the supplier lanes matrix as input

function classify_pickup(
    pickup_date::Date,
    pickup_location_id,
    delivery_location_id,
    supplier_lanes
)
    travel_time = supplier_lanes[(pickup_location_id, delivery_location_id)].day
    return pickup_date + day(travel_time) # Estimated time of arrival
end

# Calculate the Estimated Time of Arrival if shipment is picked up
