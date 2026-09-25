
function ProjectDeliveryStatus(ETA::Date, RDD::Date, RiskInterval::Int)
    if ETA <= RDD - RiskInterval
        deliveryStatus = "ON_TIME"
    elseif ETA >= RDD + RiskInterval
        deliveryStatus = "URGENT"
    else
        deliveryStatus = "AT_RISK"
    end
    return deliveryStatus

end


# riskintervall in days (int)
# deliveryStatus currently as string