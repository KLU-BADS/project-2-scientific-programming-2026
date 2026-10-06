using CSV
using DataFrames
using Dates

const DEFAULT_RISK_INTERVAL = 2

const STAGE_DELIVERED = 1
const STAGE_AT_HUB = 2
const STAGE_PICKUP_PLANNED = 3

const STATUS_ON_TRACK = 4
const STATUS_AT_RISK = 5
const STATUS_URGENT = 6

const STATUS_ON_TIME = 7
const STATUS_LATE = 8
const STATUS_PENDING = 0

function status_for_delivered(rdd::Date, actual_date::Date)
    return classify_delivery(rdd, actual_date) == "ON_TIME" ? STATUS_ON_TIME : STATUS_LATE
end

function classify_supplier(pickup_planned_date, pickup_actual_date,
                            pickup_location_id, delivery_location_id, supplier_lanes)
    pickup_date = coalesce(pickup_actual_date, pickup_planned_date)
    ismissing(pickup_date) && return missing
    return classify_pickup(pickup_date, pickup_location_id, delivery_location_id, supplier_lanes)
end

function classify_row(row, hub_lanes, supplier_lanes; risk_interval::Int=DEFAULT_RISK_INTERVAL)
    stage = determine_tracking_status(row)

    if stage == STAGE_DELIVERED
        eta = row.actual_delivery_date
        status = status_for_delivered(row.requested_delivery_date, eta)
    elseif stage == STAGE_AT_HUB
        eta = classify_hub(row.hub_arrival_date, row.pickup_location_id, row.delivery_location_id, hub_lanes)
        status = shipment_delivery_status(eta, row.requested_delivery_date, risk_interval)
    elseif stage == STAGE_PICKUP_PLANNED
        eta = classify_supplier(row.pickup_planned_date, row.pickup_actual_date,
                                 row.pickup_location_id, row.delivery_location_id, supplier_lanes)
        status = ismissing(eta) ? STATUS_PENDING :
                 shipment_delivery_status(eta, row.requested_delivery_date, risk_interval)
    else
        return nothing  # stage == 0: determine_tracking_status's row===missing edge case
    end

    return (project_id = row.project_id, shipment_id = row.shipment_id, item_code = row.item_code,
            stage = stage, status = status, estimated_arrival = eta)
end

function main(; risk_interval::Int=DEFAULT_RISK_INTERVAL, write_output::Bool=true)
    report, issues = build_report(joined, hub_lanes, supplier_lanes; risk_interval=risk_interval)
    summary = summarize(report)

    for issue in issues
        @warn issue
    end

    if write_output
        output_path = joinpath(@__DIR__, "..", "outputs", "delivery_status_report.csv")
        CSV.write(output_path, DataFrame(report))
        @info "Report written to $output_path"
    end

    return (report = report, summary = summary, issues = issues)
end
