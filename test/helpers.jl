# Today's date, fixed once so every test in a run uses the same day.
# determine_tracking_status() compares with today(), so tests about the delivered stage use dates relative to TODAY instead of fixed dates.
const TODAY = today()

# Location IDs used in the tests (from locations.jl): 1 = shanghai, 7 = rotterdam, 13 = hamburg, 14 = hamburg dc, 17 = leipzig dc
# Small lane lookups with only the lanes the tests need, so the tests don't depend on the real lane CSV files.
const TEST_HUB_LANES = Dict(
    (7, 17)  => Project2.Lane(7, 17, 3),    # Rotterdam -> Leipzig DC, 3 days
    (13, 14) => Project2.Lane(13, 14, 0),   # Hamburg -> Hamburg DC, 0 days
)
const TEST_SUPPLIER_LANES = Dict(
    (1, 14) => Project2.Lane(1, 14, 24),    # Shanghai -> Hamburg DC, 24 days
    (7, 17)  => Project2.Lane(7, 17, 5),    # Rotterdam -> Leipzig DC, 5 days
)

# Builds one row with the same fields as a row of `joined`. Every field has a
# default (an active item in transit from Rotterdam to Leipzig DC, RDD in 20
# days), so a test only writes the fields it is about.
function make_row(;
    active = true,
    item_code = "ITEM-1",
    project_id = "P-1",
    shipment_id = "S-1",
    requested_delivery_date = TODAY + Day(20),
    actual_delivery_date = missing,
    hub_arrival_date = missing,
    pickup_planned_date = missing,
    pickup_actual_date = missing,
    pickup_location_id = 7,
    delivery_location_id = 17,
)
    return (
        active = active,
        item_code = item_code,
        project_id = project_id,
        shipment_id = shipment_id,
        requested_delivery_date = requested_delivery_date,
        actual_delivery_date = actual_delivery_date,
        hub_arrival_date = hub_arrival_date,
        pickup_planned_date = pickup_planned_date,
        pickup_actual_date = pickup_actual_date,
        pickup_location_id = pickup_location_id,
        delivery_location_id = delivery_location_id,
    )
end

