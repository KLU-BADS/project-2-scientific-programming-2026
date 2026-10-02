using Dates
#uses hub_arrival_date, pickup_location_id and delivery_location_id and the hub lanes matrix as input

function ClassifyHub(hub_arrival_date::Date, pickup_location_id, delivery_location_id, hub_lanes)
    TravelTime = hub_lanes[(pickup_location_id, delivery_location_id)].day
    return hub_arrival_date + day(TravelTime) # Estimated time of arrival
end

#calculate the Estimated Time of Arrival if shipment is at a Hub
