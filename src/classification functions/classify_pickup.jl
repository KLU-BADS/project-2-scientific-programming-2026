using Dates

# Calculates the Estimated Time of Arrival (ETA) for a shipment
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
    travel_time = supplier_lanes[
        (pickup_location_id, delivery_location_id)
    ].day

    return pickup_date + Day(travel_time)  # Estimated time of arrival
end

# Returns the Estimated Time of Arrival if the shipment
# is picked up from the supplier.
