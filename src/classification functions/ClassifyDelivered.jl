using Dates

# Uses required_delivery_date and actual_delivery_date as input
#
# Status codes:
# 1 = Already delivered
# 2 = At a hub
# 3 = At supplier
# 4 = On time
# 5 = At risk
# 6 = Urgent
#
# A shipment with an actual delivery date is classified
# as already delivered.

function classify_delivery(
    required_delivery_date::Date,
    actual_delivery_date::Date
)
    return 1 # Already delivered
end

# Determines the tracking status after the shipment has been delivered.
