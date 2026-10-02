using Dates

#uses current row of joined table as input

function determine_tracking_status(row)
   if ismissing(row)
        return 0 #missing
    end


    if !ismissing(row.actual_delivery_date) && row.actual_delivery_date < today()
        return 1 #already delivered
    elseif !ismissing(row.hub_arrival_date)
        return 2 #at a Hub
    else
        return 3 #at supplier
    end   
    
end

# Determines where the shipment was last seen.
# Already Delivered(1), At a Hub(2) or at a Supplier(3) ['pickup planned']
# Return 0 if the row is missing.
# To be used for ETA calculation in various classify function.
