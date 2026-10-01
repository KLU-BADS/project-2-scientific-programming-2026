
#uses calculated ETA, RDD of current row of joined table and a risk interval as input

function ShipmentDeliveryStatus(ETA::Date, RDD::Date, RiskInterval::Int)
    if ETA <= RDD - RiskInterval
        return 1 #on time
    elseif ETA >= RDD + RiskInterval
        return 2 #urgent
    else
        return 3 #at risk
    end

end


# Determines if the shipment is currently on time(1), at risk(2) or urgent(3)
# Based on ETA, RDD and risk interval
