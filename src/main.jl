using CSV
using DataFrames
using Dates


"""
    DEFAULT_RISK_INTERVAL = 2

Tolerance in days around the requested delivery date, used by
`shipment_delivery_status`. It can be changed per run:
`main(risk_interval = 3)`.
"""
const DEFAULT_RISK_INTERVAL = 2
"""
    DEFAULT_DATA_FOLDER

Folder with the four input CSV files
"""
const DEFAULT_DATA_FOLDER = normpath(joinpath(@__DIR__, "..", "data"))

"Tracking stage 1, already delivered (from `determine_tracking_status`)."
const STAGE_DELIVERED = 1             # determine_tracking_status
"Tracking stage 2, at a hub (from `determine_tracking_status`)."
const STAGE_AT_HUB = 2                # determine_tracking_status
"Tracking stage 3, at the supplier (from `determine_tracking_status`)."
const STAGE_AT_SUPPLIER = 3           # determine_tracking_status
"Status 4, in transit and on time (from `shipment_delivery_status`)."
const STATUS_ON_TIME = 4              # shipment_delivery_status
"Status 5, in transit and at risk (from `shipment_delivery_status`)."
const STATUS_AT_RISK = 5              # shipment_delivery_status
"Status 6, in transit and urgent (from `shipment_delivery_status`)."
const STATUS_URGENT = 6               # shipment_delivery_status
"Status 7, delivered on time (from `classify_delivered`)."
const STATUS_DELIVERED_ON_TIME = 7    # classify_delivered
"Status 8, delivered late (from `classify_delivered`)."
const STATUS_DELIVERED_LATE = 8       # classify_delivered

"""
    load_data(data_folder = DEFAULT_DATA_FOLDER) -> NamedTuple

The Init step of the activity diagram: read the four CSV files, clean them,
join each order item to its shipment (Item Code = product code), add the
location IDs and build both lane lookups.

Returns `(joined, hub_lanes, supplier_lanes)`.
"""
function load_data(data_folder = DEFAULT_DATA_FOLDER)
    raw = read_raw_data(data_folder)

    internal = clean_internal(raw.internal)
    scm = clean_scm(raw.scm)

    # Every order item is matched to its shipment: Item Code = product code.
    joined = leftjoin(internal, scm; on = :item_code => :product_code, matchmissing = :error)
    add_location_ids!(joined, location_ids)

    supplier_lanes = build_lane_lookup(clean_lane_matrix(raw.supplier_lanes), location_ids)
    hub_lanes = build_lane_lookup(clean_lane_matrix(raw.hub_lanes), location_ids)

    return (joined = joined, hub_lanes = hub_lanes, supplier_lanes = supplier_lanes)
end

"""
    classify_row(row, hub_lanes, supplier_lanes; risk_interval = DEFAULT_RISK_INTERVAL) -> NamedTuple or nothing

Classify one row of `joined`, following the branches of the activity
diagram:

- delivered (1): status from `classify_delivered` (7 or 8); the ETA is the actual delivery date
- at a hub (2): ETA from `classify_hub`, status from `shipment_delivery_status` (4, 5 or 6)
- at supplier (3): ETA from `classify_pickup` using the actual pickup date if known, otherwise the planned one; status from `shipment_delivery_status` (4, 5 or 6)

Returns `(stage, status, eta)`, or `nothing` if the row cannot be
classified (no tracking stage, or at supplier without any pickup date).
"""
function classify_row(row, hub_lanes, supplier_lanes; risk_interval::Int = DEFAULT_RISK_INTERVAL)
    stage = determine_tracking_status(row)

    if stage == STAGE_DELIVERED
        eta = row.scm_actual_delivery_date
        status = classify_delivered(row.requested_delivery_date, eta)

    elseif stage == STAGE_AT_HUB
        eta = classify_hub(row.hub_arrival_date, row.pickup_location_id,
                           row.delivery_location_id, hub_lanes)
        status = shipment_delivery_status(eta, row.requested_delivery_date, risk_interval)

    elseif stage == STAGE_AT_SUPPLIER
        pickup_date = coalesce(row.pickup_actual_date, row.pickup_planned_date)
        ismissing(pickup_date) && return nothing

        eta = classify_pickup(pickup_date, row.pickup_location_id,
                              row.delivery_location_id, supplier_lanes)
        status = shipment_delivery_status(eta, row.requested_delivery_date, risk_interval)

    else
        return nothing    # 0: determine_tracking_status got a missing row
    end

    return (stage = stage, status = status, eta = eta)
end

"""
    build_report(joined, hub_lanes, supplier_lanes; risk_interval = DEFAULT_RISK_INTERVAL) -> (row_collector, issues)

The "repeat while Shipment left?" loop of the activity diagram. Classifies
every active row of `joined` with `classify_row` and collects
`(item_code, status, eta)` for each one in `row_collector`, the format
`building_small` reads.

Rows that are not active (Active is "no" or empty) are left out silently.
Rows with a missing RDD, a missing pickup or delivery location, or no
classification are skipped and described in `issues`, so one bad row never
stops the run.
"""
function build_report(joined, hub_lanes, supplier_lanes; risk_interval::Int = DEFAULT_RISK_INTERVAL)
    row_collector = []          # Output: "this goes before the loop"
    issues = String[]

    for row in eachrow(joined)
        row.active === true || continue

        if ismissing(row.requested_delivery_date)
            push!(issues, "Item $(row.item_code): missing RDD, skipped")
            continue
        end
        if ismissing(row.pickup_location_id) || ismissing(row.delivery_location_id)
            push!(issues, "Item $(row.item_code): unknown pickup or delivery location, skipped")
            continue
        end

        result = classify_row(row, hub_lanes, supplier_lanes; risk_interval = risk_interval)
        if result === nothing
            push!(issues, "Item $(row.item_code): no tracking stage or pickup date, skipped")
            continue
        end

        # Output: "inside the loop"
        push!(row_collector, (row.item_code, result.status, result.eta))
    end

    return row_collector, issues
end

"""
    summarize(row_collector) -> NamedTuple

Count the classified items per status code. Returns
`(total_items, counts_by_status, immediate_attention_count)`, where
`immediate_attention_count` is the number of urgent items (status 6).
Skipped items are not counted.
"""
function summarize(row_collector)
    counts = Dict{Int,Int}()
    for (item_code, status, eta) in row_collector
        counts[status] = get(counts, status, 0) + 1
    end

    return (
        total_items = length(row_collector),
        counts_by_status = counts,
        immediate_attention_count = get(counts, STATUS_URGENT, 0),
    )
end

"""
    main(; risk_interval = DEFAULT_RISK_INTERVAL, data_folder = DEFAULT_DATA_FOLDER)

Run the whole program: load the data, classify every shipment, print the
skipped items and a short summary, then build the report and export it as
`Final_Report.csv` with the Output functions.

Returns `(report, summary, issues)`.

# Examples
```julia
using Project2
result = main()
result.summary.immediate_attention_count
```
"""
function main(; risk_interval::Int = DEFAULT_RISK_INTERVAL, data_folder = DEFAULT_DATA_FOLDER)
    # Init (load & check data)
    data = load_data(data_folder)

    # repeat over all shipments
    row_collector, issues = build_report(data.joined, data.hub_lanes, data.supplier_lanes;
                                         risk_interval = risk_interval)
    for issue in issues
        @warn issue
    end

    summary = summarize(row_collector)
    @info "Classified $(summary.total_items) items, $(summary.immediate_attention_count) urgent, $(length(issues)) skipped"

    # Create report (Output)
    final_data_frame = building_dataframe(data.joined)
    small_data_frame = building_small(row_collector)
    report = all_together(final_data_frame, small_data_frame)
    pdf_creation(report)
    
    return (report = report, summary = summary, issues = issues)
end




















