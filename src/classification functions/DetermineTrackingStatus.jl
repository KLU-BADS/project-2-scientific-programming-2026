using Dates
function DetermineTrackingStatus(shipID::Int)
    if shipID.delActual < today() && shipID.delActual != missing
        trackingStatus = "DELIVERED"
    elseif shipID.hubArrival != missing
        trackingStatus = "At_HUB" 
    else
        trackingStatus = "PICKUP_PLANNED"
    end   
        return trackingStatus
end

# using strings as tracking status for now, number probably better for future use
# shipID structure needs to be defined in order to use this function
# delActual and other dates need to be in Date format