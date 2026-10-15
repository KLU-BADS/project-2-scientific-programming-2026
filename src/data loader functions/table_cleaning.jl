"""
    convert_column!(table, column, converter) -> table

Apply `converter` to every value of one column and store the result in the
same column, changing `table` in place.

If a value cannot be converted, a new error is thrown that names the column
and the data row, followed by the original message, e.g.
`Column 'active', data row '2': 'ArgumentError: ...'`.
"""
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

"""
    clean_internal(raw_table) -> DataFrame

Clean the internal order table (`Internal_db.csv`).

Keeps and renames nine columns: Active → `active`, Business Unit →
`business_unit`, Material → `material`, Item Code → `item_code`, Quantity →
`quantity`, Project ID → `project_id`, k EUR → `k_eur`, RDD →
`requested_delivery_date`, CDD → `customer_desired_date`. All values are
trimmed with `clean_text`, then `active` becomes `Bool`, `quantity` and
`k_eur` become `Float64` and both dates become `Date`. Other columns are
dropped.
"""
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
        "CDD" => :customer_desired_date
    )  
    for column in names(table)
        convert_column!(table, column, clean_text)
    end 

    # Converting all columns that should not remain a string
    convert_column!(table, :active, parse_active)
    for column in (:quantity, :k_eur)
        convert_column!(table, column, parse_quantity)
    end 

    # Calling the date formatting function 
     for column in (:requested_delivery_date, :customer_desired_date)
        convert_column!(table, column, parse_delivery_date)
    end 

    return table
end 

"""
    clean_scm(raw_table) -> DataFrame

Clean the shipment table from the SCM system (`SCM_db.csv`).

Keeps and renames thirteen columns, including `product_code` (from
"Sub shipment, delivery line, product code"), which `load_data` matches to
`item_code`, and the milestone dates `pickup_planned_date`,
`pickup_actual_date`, `hub_arrival_date` and `scm_actual_delivery_date`.
Cities are normalized with `clean_location`, countries and transport mode
are lowercased, and the four dates become `Date`.
"""
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

"""
    clean_lane_matrix(table) -> DataFrame

Clean a lane matrix (origin cities in the first column, distribution centers
as column headers, transit days in the cells).

Normalizes the origin names and the column headers with `clean_location`
and converts every day value with `parse_lane_days`. Changes `table` in
place and returns it.
"""
function clean_lane_matrix(table)
    origin_column = names(table)[1]
    convert_column!(table, origin_column, clean_location)

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
