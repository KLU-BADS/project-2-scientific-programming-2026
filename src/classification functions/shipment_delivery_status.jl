
#uses calculated estimated_time_of_arrival, requested_delivery_date of current row of joined table and a risk interval as input

function shipment_delivery_status(estimated_time_of_arrival::Date, requested_delivery_date::Date, risk_interval::Int)
    if estimated_time_of_arrival <= requested_delivery_date - day(risk_interval)
        return 4 #on time
    elseif estimated_time_of_arrival >= requested_delivery_date + day(risk_interval)
        return 6 #urgent
    else
        return 5 #at risk
    end

end


# Determines if the shipment is currently on time(4), at risk(5) or urgent(6)
# Based on estimated_time_of_arrival, requested_delivery_date and risk_interval
