using Dates

function ClassifyPickup(
    PickupDate::Date,
    PickupCity::String,
    Destination::String
)
    TravelTime = PickupMatrix(PickupCity, Destination)
    ETA = PickupDate + Day(TravelTime)

    return ETA
end

# naming conventions of matrices and variables TBD
# make sure correct data form (date, INT for days etc.)
# City and Destinaton as strings?
