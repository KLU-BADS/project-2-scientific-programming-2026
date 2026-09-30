
function ClassifyHub(HubDate::Date, origin_id, destination_id, hub_lanes)
    TravelTime = hub_lanes[(origin_id, destination_id)].day
    ETA::Date = HubDate + TravelTime
    return ETA
end


# check for correct access keywords of HubMatrix
# Traveltime in days
# city and destination as strings?