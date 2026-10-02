# this goes before the loop
row_collector = []

# inside the loop
push!(row_collector, (item_code, ShipmentDeliveryStatus, ETA))


# Function that flag the late ot urgent items
# for the late or urgent highlight in red and try to add a flag or point in red
# Need to implement what if is at risk and highlight it in yellow
function flagging(ShipmentDeliveryStatus)
    if ShipmentDeliveryStatus == 3 || ShipmentDeliveryStatus == "LATE"
        return :critical
    elseif ShipmentDeliveryStatus == 2
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
df = DataFrame(Project_ID = joined_csv[!, :Project_ID], Shipment_ID = joined_csv[!, :Shipment_ID], Items = joined_csv[!, :item_code], Material = joined_csv[!, :material])

# Push all the delivery status and ETA matching the item code
del_values = getindex.(row_collector, 2)
final_time = getindex.(row_collector, 3)

df.DeliveryStatus = del_values
df.ETA = final_time

# Need to left join row collector with df

# item_code is the primary key in the joined csv
# joined csv is the data set joined with the initial two data sets
# look at the joined csv for getting the column I need