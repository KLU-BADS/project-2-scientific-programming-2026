using Dates

function ClassifyPickup(
    PickupDate::Date,
    origin_id,
    destination_id,
    supplier_lanes
)
    TravelTime = supplier_lanes[(origin_id, destination_id)].day
    ETA::Date = PickupDate + Day(TravelTime)

    return ETA
end

# Calculate the Estimated Time of Arrival if shipment is picked up
