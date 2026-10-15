"""
    parse_lane_days(value) -> Union{Int, Missing}

Convert one cell of a lane matrix into a whole number of transit days.

An empty cell becomes `missing`. Text, decimals and negative numbers throw
an `ArgumentError`. `value` may be a string or `missing`.

# Examples
```julia
parse_lane_days(" 3 ")   # 3
parse_lane_days("abc")   # throws ArgumentError
```
"""
function parse_lane_days(value)
       # Trim the cell; empty and missing cells both become missing
    text = clean_text(value)

    if ismissing(text)
        return missing
    end

    days = tryparse(Int, text) # if values couldn't be turned into an integer value they Julia will insert "nothing" 
    
    if isnothing(days)
        throw(ArgumentError("Expected a whole number of days, but found: '$value'"))
    end 

    if days < 0 
        throw(ArgumentError("Lane duration must not be negative '$days'"))
    end 

    return days
end 

"""
    parse_delivery_date(value) -> Union{Date, Missing}

Convert a date cell into a `Date`.

Accepts the European format day.month.year (one or two digits for day and
month) and the ISO format year-month-day. A time after the date, such as
`00:00:00`, is ignored. Empty cells become `missing`; any other format
throws an `ArgumentError` instead of being guessed.

# Examples
```julia
parse_delivery_date("27.09.2026")            # Date(2026, 9, 27)
parse_delivery_date("2026-09-29 00:00:00")   # Date(2026, 9, 29)
```
"""
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

"""
    parse_quantity(value) -> Union{Float64, Missing}

Convert a number written in American format into a `Float64`.

Accepts an optional leading `+`, thousands separated by commas and an
optional decimal part. The commas are removed before parsing. European
format (`1.234,50`) and negative numbers throw an `ArgumentError`. Empty
cells become `missing`.

# Examples
```julia
parse_quantity("1,234.50")   # 1234.5
```
"""
function parse_quantity(value)
    text = clean_text(value)
    if ismissing(text)
        return missing 
    end 

    # Allows patterns like 1234, +12, 1,234.5 and 1,234,567; rejects everything else (negative numbers included)
    pattern = r"^[+]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$"

    if !occursin(pattern, text)
        throw(ArgumentError(
            "Expected an American float pattern such as 1,234.50, found '$text' instead"
            ))
    end 

    normalized = replace(text, "," => "")

    return parse(Float64, normalized)
end 

"""
    parse_active(value) -> Union{Bool, Missing}

Convert the Active column into a `Bool`: `"yes"` → `true`, `"no"` →
`false`, in any casing. Any other text throws an `ArgumentError`; empty
cells become `missing`.

# Examples
```julia
parse_active(" No ")   # false
```
"""
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
