using Dates

# Calculates the Estimated Time of Arrival (ETA) of a shipment
# after it is picked up from the supplier.
#
# Inputs:
#   pickup_date          -> Date on which the shipment is picked up
#   pickup_location_id   -> Supplier/pickup location ID
#   delivery_location_id -> Destination location ID
#   supplier_lanes       -> Supplier lane matrix
#
# Output:
#   Estimated Time of Arrival as a Date

function classify_pickup(
    pickup_date::Date,
    pickup_location_id,
    delivery_location_id,
    supplier_lanes
)
    # Get travel time from supplier to destination
    travel_time = supplier_lanes[
        (pickup_location_id, delivery_location_id)
    ].day

    # Calculate and return the Estimated Time of Arrival
    return pickup_date + Day(travel_time)
end
