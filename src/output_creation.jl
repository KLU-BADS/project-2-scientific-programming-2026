# Libraries
using DataFrames

"""
    flagging(shipment_delivery_status) -> Symbol

Severity of a delivery status code, used for the report's `Severity` column:

- `missing` (item skipped by the main pipeline) → `:watch`
- `6` (urgent) → `:critical`
- `8` (delivered late) → `:late_arrival`
- `5` (at risk) → `:watch`
- anything else (`4`, `7`) → `:ok`
"""
function flagging(shipment_delivery_status)
    if ismissing(shipment_delivery_status)
        return :watch
    elseif shipment_delivery_status == 6
        return :critical
    elseif shipment_delivery_status == 8
        return :late_arrival
    elseif shipment_delivery_status == 5
        return :watch
    else
        return :ok
    end
end

"""
    icon_for(severity) -> String

Icon shown in the report for a severity: `:critical` → 🚩,
`:late_arrival` → ❌, `:watch` → ⚠️, anything else → ✓.
"""
function icon_for(severity)
    if severity == :critical
        return "🚩"
    elseif severity == :late_arrival
        return "❌"
    elseif severity == :watch
        return "⚠️"
    else
        return "✓"
    end
end

"""
    building_dataframe(joined) -> DataFrame

Item details for the report, one row per item of `joined`, with the columns
`Project_ID`, `Shipment_ID`, `Items_Number` and `Material`.
"""
function building_dataframe(joined)
    final_data_frame = DataFrame(Project_ID = joined[!, :project_id], Shipment_ID = joined[!, :shipment_id], Items_Number = joined[!, :item_code], Material = joined[!, :material])
    return final_data_frame
end

"""
    building_small(row_collector) -> DataFrame

Turn the main pipeline's `row_collector`, a list of
`(item_code, status, eta)` tuples, into a table with the columns
`Delivery_Status`, `ETA` and `Items_Number`, one row per classified item.
"""
function building_small(row_collector)  
    item_codes = getindex.(row_collector, 1)
    delivery_statuses = getindex.(row_collector, 2)
    estimated_arrivals = getindex.(row_collector, 3)
    small_data_frame = DataFrame(Delivery_Status = delivery_statuses, ETA = estimated_arrivals, Items_Number = item_codes)
    return small_data_frame
end

"""
    all_together(final_data_frame, small_data_frame) -> DataFrame

Build the final report: left-join the classification results onto the item
details by `Items_Number`, keeping the row order of `final_data_frame`, then
add the columns `Severity` (from `flagging`) and `Icon` (from `icon_for`).
Items the main pipeline skipped keep an empty status and get `:watch` / ⚠️.
"""
function all_together(final_data_frame, small_data_frame)
    report = leftjoin(final_data_frame, small_data_frame, on = :Items_Number, order = :left)
    report.Severity = flagging.(report.Delivery_Status)
    report.Icon = icon_for.(report.Severity)
    return report
end 

"""
    export_csv(report::DataFrame, file_name = "Final_Report.csv") -> String

Write the final report to a semicolon-separated CSV file in the current
folder and return the file name.

The semicolon separator lets the file open correctly in German and
European Excel. Severities are written as plain text (e.g. `late_arrival`)
and missing values as empty cells.
"""
function export_csv(report::DataFrame, file_name = "Final_Report.csv")
    CSV.write(file_name, report; delim = ";")
    return file_name
end
 
"""
    report_creation(report) -> String

Show a preview of the report, then export it with
`export_csv` and return the file name.
"""
function report_creation(report)
    if isdefined(Main, :vscodedisplay)
        vscodedisplay(report)
    else
        println("\n--- Preview of the Final Report ---")
        show(first(report, 50), allcols = true)
    end
    return export_csv(report)
end
