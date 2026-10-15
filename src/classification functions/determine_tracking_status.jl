using Dates

"""
    determine_tracking_status(row) -> Int

Decide where the shipment of one row of `joined` was last seen. The checks
run in this order, as in the activity diagram:

- `0`: the row is `missing`
- `1` (already delivered): `scm_actual_delivery_date` is known and before `today()`
- `2` (at a hub): `hub_arrival_date` is known
- `3` (at supplier): otherwise

The SCM delivery dates in the data all lie in the past, so `today()` does not
change the result on the current data. A delivery dated on the run day
counts as not delivered yet.
"""
function determine_tracking_status(row)
   if ismissing(row)
        return 0 #missing
    end
    if !ismissing(row.scm_actual_delivery_date) && row.scm_actual_delivery_date < today()
        return 1 #already delivered
    elseif !ismissing(row.hub_arrival_date)
        return 2 #at a Hub
    else
        return 3 #at supplier
    end   
    
end


