#Converts every value in a column with a supplied converter, than stores the results in a directly in the same table 
function convert_column!(table, column, converter)
    # 
    converted = map(enumerate(table[!, column])) do (row, value) # equivilant to map((row, value) -> converter(value), enumerate(table[!, column]))
        try
            converter(value)
        # If there is an error catch, err will saves it,  sprint turns it into a text. Error then throws a new error and adds the column and row context
        catch err
            detail = sprint(showerror, err)
            error("Column '$column', data row '$row': '$detail'")
        end
    end

    table[!, column] = converted
    return table
end


function clean_internal(raw_table)
    table = select(
        raw_table,
        "Active" => :active,
        "Business Unit" => :business_unit,
        "Material" => :material,
        "Item Code" => :item_code,
        "Quantity" => :quantity,
        "Project ID" => :project_id,
        "k EUR" => :k_eur,
        "RDD" => :requested_delivery_date,
        "CDD" => :actual_delivery_date 
    )

    #= Calls the function clean_text and checks whether the transformation was successful, we are just using this function to  
    also strip out values, remember all values are intially strings and are then turned into the respective data format 
        =#    
    for column in names(table)
        convert_column!(table, column, clean_text)
    end 

    # Converting all columns that should not remain a string
    convert_column!(table, :active, parse_active)
    for column in (:quantity, :k_eur)
        convert_column!(table, column, parse_quantity)
    end 

    # Calling the date formatting function 
    for column in (:requested_delivery_date, :actual_delivery_date)
        convert_column!(table, column, parse_delivery_date)
    end 

    return table
end 


function clean_scm(raw_table)
    table = select(
        raw_table,
        "Project ID MP1 Reference" => :scm_project_id,
        "Shipment ID" => :shipment_id,
        "Sub shipment, delivery line, product code" => :product_code,
        "Pickup city" => :pickup_city,
        "Pickup country" => :pickup_country,
        "Delivery city" => :delivery_city,
        "Delivery country" => :delivery_country,
        "Leg 1, Pickup Planned (date)" => :pickup_planned_date,
        "Leg 1, Pickup Actual (date)" => :pickup_actual_date,
        "Leg 1, Hub Arrival (date)" => :hub_arrival_date,
        "Leg n, Delivery Actual (date)" => :scm_actual_delivery_date,
        "Leg n, Transport Mode" => :transport_mode,
        "Leg 1, Carrier Name" => :carrier_name
    )

    #= Calls the function clean_text and checks whether the transformation was successful, we are just using this function to  
    also strip out values, remember all values are intially strings and are then turned into the respective data format 
        =#    
    for column in names(table)
        convert_column!(table, column, clean_text)
    end

     # Converting all columns that should not remain a string
    for column in (:pickup_city, :delivery_city)
        convert_column!(table, column, clean_location)
    end
   
    for column in (:pickup_country, :delivery_country, :transport_mode)
        convert_column!(table, column, clean_lowercase)
    end

     # Calling the date formatting function 
    date_columns = (
        :pickup_planned_date,
        :pickup_actual_date,
        :hub_arrival_date,
        :scm_actual_delivery_date
    )

    for column in date_columns
        convert_column!(table, column, parse_delivery_date)
    end

    return table
end


function clean_lane_matrix(table)
    # Cleaning the origing city which are stated in the first column first using the clean_location function 
    origin_column = names(table)[1]
    convert_column!(table, origin_column, clean_location)

    #= Cleaning the destination names which are stated in the first row, 
    while removing the first column which just contains "origin city/ distribution center" =#
    destination_columns = names(table)[2:end]

    for column in destination_columns
        # Convert column by column to an integer value
        convert_column!(table, column, parse_lane_days)

        # Cleaning the column names and checking for possible spelling issues
        cleaned_name = clean_location(column)

        if cleaned_name != column 
            rename!(table, column => cleaned_name)
        end 
    end 
    return table 
end 