using Dates

# Uses required_delivery_date and actual_delivery_date as input

function classify_delivery(required_delivery_date::Date, actual_delivery_date::Date)
    if required_delivery_date < actual_delivery_date
        delivery_status = "LATE"
    else
        delivery_status = "ON_TIME"
    end

    return delivery_status
end

# Calculate the Delivery Status based on the Required Delivery Date
# and the Actual Delivery Date
