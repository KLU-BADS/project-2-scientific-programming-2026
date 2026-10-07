# Libraries
using DataFrames
# using PlutoUI

# this goes before the loop
row_collector = []

# inside the loop
push!(row_collector, (item_code, shipment_delivery_status, ETA))


# Function that flag the late ot urgent items
# for the late or urgent highlight in red and try to add a flag or point in red
# Need to implement what if is at risk and highlight it in yellow
function flagging(shipment_delivery_status)
    if shipment_delivery_status == 6 || shipment_delivery_status == "LATE"
        return :critical
    elseif shipment_delivery_status == 5
        return :watch
    else
        return :ok
    end
end

# Function that colors each row based on the severity of the Delivery Status and add a Unicode to it
function style_for(severity)
    if severity == :critical
        return (color = "red", icon = "🚩")
    elseif severity == :watch
        return (color = "yellow", icon = "⚠️")
    else
        return (color = "green", icon = "✓")
    end
end

# Creating a datframe with only the important item 
df = DataFrame(Project_ID = joined_csv[!, :Project_ID], Shipment_ID = joined_csv[!, :Shipment_ID], Items_Number = joined_csv[!, :item_code], Material = joined_csv[!, :material])

# Push all the delivery status and ETA into a small dataframe
items_code = getindex.(row_collector, 1)
del_values = getindex.(row_collector, 2)
final_time = getindex.(row_collector, 3)

small_df = DataFrame(Delivery_Status = del_values, ETA = final_time, Items_Number = items_code)

# Need to left join row collector with df
report = leftjoin(df, small_df, on = :Items_Number)

# Creating a function that print a PDF file
function export_pdf_html(report::DataFrames, file_name = "Final_Report.html")
    buf = IOBuffer()
    show(buf, MIME("text/maekdown"), report, allrows = true, allcols = true)
    md_table = String(take!(buf))

    typst_doc = """
    #set page (
        paper: "a4"
        margin: (top: 1.5cm, bottom: 1.5cm, left: 1cm, right: 1cm),
        header: align(right)[Project Report - Page #counter(page).display()]
    )
    #set text(font: "Times New Roman", size: 11pt)
    #raw("$md_tabel")
"""
typst_compile(typst_doc, file_name)
end


# Displaying of the final report both in VS Code and in the terminal
if isdefined(Main, :vscodedisplay)
    vscodedisplay(report)
else
    println("\n--- Preview of the Final Report ---")
    show(report, maxrows = 50, allcols = true)
    export_pdf_html(report)
end

#region search bar
# HTML search bar code
# function row_to_html(i)
#     severity = flagging(report.Delivery_Status[i])
#     return """<tr class = "$(severity)">
#     <td>$(report.Project_ID[i])</td>
#     <td>$(report.Shipment_ID[i])</td> 
#     <td>$(report.Delivery_Status[i])</td> 
# </tr>"""
# end

# creating a vector for the strings
# row_html = []

# creating a for loop that collect every string
# for i in 1:nrow(report)
#     push!(row_html, row_to_html(i))
# end

# merges the lines together
# joined_rows = join(row_html, "\n")

# header of the HTML table
# header = """<tr>
#     <th>Project ID</th>
#     <th>Shipment ID</th>
#     <th>Delivery Status</th>
# </tr>"""

# full table for the HTML
# full_table = """<table>
# $(header)
# $(joined_rows)
# </table>"""

# CSS code for coloring the severity of the Delivery status
# css = """
# .critical {
#     background-color: red;
# }

# .watch {
#     background-color: yellow;
# }
# """
# creating the document in HTML
# document_html = """
# <!DOCTYPE html>
# <html>
# <head>
#     <style>
#         $(css)
#     </style>
# </head>
# <body>
#     <input type="text" id="searchBox" placeholder="Type Project ID to filter">
#     $(full_table)
#     <script>
#         let searchBox = document.getElementById("searchBox")
#     </script>
# </body>
# </html>
# """
#endregion

# region Pluto
# Live search bar, search query variable
# @bind search_query TextField(placeholder = "Type Project_ID to filter instantly")

# this cell re-runs instantly whenever 'search query' changes
# filtered_df = if isempty(strip(search_query))
#     report
# else
#     filter(row -> occursin(search_query, string(row.Project_ID)), report)
# end

# figuring out how many pages we have 
# total_rows = nrow(filtered_df)

# page_size = 15

# max_page = ceil(Int, total_rows / page_size)

# wrapping the dataframe in only 15 rows
# @bind page Slider(1:max_page, default = 1, show_value = true)

# constraint to make the page shows what the user whant
# safe_page = clamp(page, 1, max(max_page, 1))

# start_row = (safe_page - 1) * page_size + 1

# end_row = min(safe_page * page_size, total_rows)

# page_df = filtered_df[start_row:end_row, :]

# show the page number out of the total page
# md"Page $safe_page of $max_page."

# item_code is the primary key in the joined csv
# joined csv is the data set joined with the initial two data sets
# look at the joined csv for getting the column I need
# endregion