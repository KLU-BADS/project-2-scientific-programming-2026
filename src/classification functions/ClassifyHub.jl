
function ClassifyHub(HubDate::Date, PickupCity, Destination)
    TravelTime = HubMatrix(PickupCity, Destination)
    ETA::Date = HubDate + TravelTime
    return ETA
end


# check for correct access keywords of HubMatrix
# Traveltime in days
# city and destination as strings?