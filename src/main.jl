using CSV
using DataFrames
using Dates


## Settings and status codes
# Tolerance in days around the RDD.
const DEFAULT_RISK_INTERVAL = 2
# Folder with the four input CSV files.
const DEFAULT_DATA_FOLDER = normpath(joinpath(@__DIR__, "..", "data"))

# Codes returned by the classification functions
const STAGE_DELIVERED = 1             # determine_tracking_status
const STAGE_AT_HUB = 2                # determine_tracking_status
const STAGE_AT_SUPPLIER = 3           # determine_tracking_status
const STATUS_ON_TIME = 4              # shipment_delivery_status
const STATUS_AT_RISK = 5              # shipment_delivery_status
const STATUS_URGENT = 6               # shipment_delivery_status
const STATUS_DELIVERED_ON_TIME = 7    # classify_delivered
const STATUS_DELIVERED_LATE = 8       # classify_delivered

## Init: load & check data
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

# Classify one row
function classify_row(row, hub_lanes, supplier_lanes; risk_interval::Int = DEFAULT_RISK_INTERVAL)
    stage = determine_tracking_status(row)

    if stage == STAGE_DELIVERED
        eta = row.actual_delivery_date
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

# Loop over all shipments
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

# Summary
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

# Entry point
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




















