
function parse_lane_days(value)
    # Remove all whitespaces preceeding and superceeding the cell value 
    text = strip(value)

    # If cells don't contain a value they will be turned into a missing value 
    if isempty(text)
        return missing 
    end

    days = tryparse(Int, text) # if values couldn't be turned into an integer value they Julia will insert "nothing" 
    
    if days == nothing 
        throw(ArgumentError("Expected a whole number of days, but found: '$value'"))
    end 

    if days < 0 
        throw(ArgumentError("Lane duration must not be negative '$days'"))
    end 

    return days
end 


function parse_delivery_date(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end

    # Example:
    # "2026-09-29 00:00:00" becomes ["2026-09-29", "00:00:00"]
    parts = split(text)
    date_text = parts[1]

    # European format: day.month.year
    if occursin(r"^\d{1,2}\.\d{1,2}\.\d{4}$", date_text)
        return Date(date_text, dateformat"dd.mm.yyyy")

    # ISO format: year-month-day
    elseif occursin(r"^\d{4}-\d{2}-\d{2}$", date_text)
        return Date(date_text, dateformat"yyyy-mm-dd")

    else
        throw(ArgumentError(
            "Expected a date such as 27.09.2026 or 2026-09-27, " *
            "optionally followed by a space and time; found '$text'"
        ))
    end
end

function parse_quantity(value)
    text = clean_text(value)
    if ismissing(text)
        return missing 
    end 

    #allows patterns like 1234; -12; +12, 1,234.5; 1,234,567; 89 and rejects everything else 
    pattern = r"^[+]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$"

    if !occursin(pattern, text)
        throw(ArgumentError(
            "Expected an American float pattern such as 1,234.50, found '$text' instead"
            ))
    end 

    normalized = replace(text, "," => "")

    return parse(Float64, normalized)
end 

function parse_active(value)
    text = clean_text(value)
    
    if ismissing(text)
        return missing
    end 

    normalized = lowercase(text)

    if normalized == "yes"
        return true
    elseif normalized == "no"
        return false 
    else 
        throw(ArgumentError(
            "Expected a value of yes or no, found '$normalized'"
        ))
    end
end 