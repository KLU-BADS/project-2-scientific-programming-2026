
#uses hub_arrival_date, origin and destination city ID and the hub lanes matrix as input

function ClassifyHub(HubDate::Date, origin_id, destination_id, hub_lanes)
    TravelTime = hub_lanes[(origin_id, destination_id)].day
    ETA::Date = HubDate + TravelTime
    return ETA
end

#calculate the Estimated Time of Arrival if shipment is at a Hub