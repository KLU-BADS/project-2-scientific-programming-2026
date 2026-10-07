using Dates

# Calculates the delivery status of a shipment after pickup.
#
# Status codes:
# 4 = On time
# 5 = At risk
# 6 = Urgent
#
# Inputs:
#   pickup_date             -> Date on which shipment is picked up
#   pickup_location_id      -> Supplier/pickup location ID
#   delivery_location_id    -> Destination location ID
#   supplier_lanes          -> Supplier lane matrix
#   requested_delivery_date -> Customer's requested delivery date
#   risk_interval           -> Allowed risk interval in days

function classify_pickup(
    pickup_date::Date,
    pickup_location_id,
    delivery_location_id,
    supplier_lanes,
    requested_delivery_date::Date,
    risk_interval::Int
)
    # Get travel time from supplier to destination
    travel_time = supplier_lanes[
        (pickup_location_id, delivery_location_id)
    ].day

    # Calculate estimated time of arrival
    estimated_time_of_arrival = pickup_date + Day(travel_time)

    # Determine delivery status
    if estimated_time_of_arrival <= requested_delivery_date - Day(risk_interval)
        return 4  # On time
    elseif estimated_time_of_arrival >= requested_delivery_date + Day(risk_interval)
        return 6  # Urgent
    else
        return 5  # At risk
    end
end
