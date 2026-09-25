
function ClassifyPickup(PickupDate::Date, PickupCity, Destination)
    Traveltime = PickupMatrix(PickupCity, Destination)
    ETA::Date = PickupDate + Traveltime
    return ETA
end

# naming conventions of matrices and variables TBD
# make sure correct data form (date, INT for days etc.)
# City and Destinaton as strings?