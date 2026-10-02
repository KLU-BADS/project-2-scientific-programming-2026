
# uses required delivery date and actual delivery date as input

function ClassifyDelivered(RDD::Date, DeliveryDate::Date)
    if RDD < DeliveryDate
        DeliveryStatus = "LATE"
    else
        DeliveryStatus = "ON_TIME"
    end

    return DeliveryStatus
end

# DeliveryStatus is currently a String
