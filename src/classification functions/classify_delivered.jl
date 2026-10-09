using Dates

# Classifies the delivery performance based on the
# required delivery date and actual delivery date.
#
# Status codes:
# 1 = Already delivered
# 2 = At a hub
# 3 = At supplier
# 4 = On time
# 5 = At risk
# 6 = Urgent
# 7 = Delivered on time
# 8 = Delivered late

function classify_delivered(
    required_delivery_date::Date,
    actual_delivery_date::Date
)
    if actual_delivery_date > required_delivery_date
        return 8  # Delivered late
    else
        return 7  # Delivered on time
    end
end

# Determines the final delivery status by comparing
# the required delivery date with the actual delivery date.
