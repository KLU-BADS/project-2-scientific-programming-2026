using Dates

# Uses pickup_date, origin and destination city IDs,
# and the pickup lanes matrix as input

function ClassifyPickup(
    PickupDate::Date,
    origin_id,
    destination_id,
    pickup_lanes
)
    TravelTime = pickup_lanes[(origin_id, destination_id)].day
    ETA::Date = PickupDate + TravelTime

    return ETA
end

# Calculate the Estimated Time of Arrival if shipment is picked up

