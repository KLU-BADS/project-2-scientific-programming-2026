using Dates

#uses current row of joined table as input

function DetermineTrackingStatus(row)
    if row.actual_delivery_date < today() && row.actual_delivery_date != missing
        return 1 #already delivered
    elseif row.hub_arrival_date != missing
        return 2 #at a Hub
    else
        return 3 #at supplier
    end   
    
end

# Determines where the shipment was last seen.
# Already Delivered(1), At a Hub(2) or at a Supplier(3) ['pickup planned']
# To be used for ETA calculation