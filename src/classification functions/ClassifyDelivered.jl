

function ClassifyDelivered(RDD::Date, delActual::Date)
    if RDD < delActual
        deliveryStatus = "LATE"
    else
        deliveryStatus = "ON_TIME"
    end
    return deliveryStatus

end

#deliveryStatus is a string for now, number probably better for future use