# Libraries
using DataFrames
using Typstry

# Function that flag the late or urgent items
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

# Function that colors each row based on the severity of the Delivery Status and add a Unicode to it
function style_for(severity)
    if severity == :critical
        return (color = "#FFCDD2", icon = "🚩")
    elseif severity == :late_arrival
        return (color = "#F3E5F5", icon = "❌")
    elseif severity == :watch
        return (color = "#FFF9C4", icon = "⚠️")
    else
        return (color = "#C8E6C9", icon = "✓")
    end
end

# Creating a function for the datframe with only the important item
function building_dataframe(joined)
    final_data_frame = DataFrame(Project_ID = joined[!, :project_id], Shipment_ID = joined[!, :shipment_id], Items_Number = joined[!, :item_code], Material = joined[!, :material])
    return final_data_frame
end

# Push all the delivery status and ETA into a small dataframe
# Creation of a small data set for items not in joined
function building_small(row_collector)  
    items_code = getindex.(row_collector, 1)
    del_values = getindex.(row_collector, 2)
    final_time = getindex.(row_collector, 3)  
    small_data_frame = DataFrame(Delivery_Status = del_values, ETA = final_time, Items_Number = items_code)
    return small_data_frame
end

# Need to left join row collector with df
function all_together(final_data_frame, small_data_frame)
    report = leftjoin(final_data_frame, small_data_frame, on = :Items_Number, order = :left)
    return report
end 

# Creating a function that print a PDF file
function export_pdf_html(report::DataFrame, file_name = "Final_Report.pdf")
    buf = IOBuffer()
    show(buf, MIME("text/markdown"), report, allrows = true, allcols = true)
    md_table = String(take!(buf))

    typst_doc = """
    #set page(
        paper: "a4",
        margin: (top: 1.5cm, bottom: 1.5cm, left: 1cm, right: 1cm),
        header: align(right)[Project Report - Page #counter(page).display()]
    )
    #set text(font: "Times New Roman", size: 11pt)
    #raw("$md_table")
"""
typst_compile(typst_doc, file_name)
end


# Displaying of the final report both in VS Code and in the terminal
# Create a function to be recall later
function pdf_creation(report)
    if isdefined(Main, :vscodedisplay)
        vscodedisplay(report)
    else
        println("\n--- Preview of the Final Report ---")
        show(report, maxrows = 50, allcols = true)
    end
    return export_pdf_html(report)
end