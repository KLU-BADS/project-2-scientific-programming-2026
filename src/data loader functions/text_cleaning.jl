"""
    clean_text(value) -> Union{String, Missing}

Trim the whitespace around one raw cell value.

Returns `missing` when `value` is `missing` or contains only whitespace.
Otherwise returns the trimmed text as a `String` (not a `SubString`), so a
cleaned column holds one element type. Runs on every column of the raw
tables before the type-specific parsers.

# Examples
```julia
clean_text("  ITEM-1  ")   # "ITEM-1"
clean_text("   ")          # missing
```
"""
function clean_text(value)
    #its necessary to check whether the input is already missing as the subsequent strip function will fail otherwise
    if ismissing(value) 
        return missing 
    end
  
    text = strip(value)

    if isempty(text)
        return missing 
    else 
        return String(text)
    end 
end

"""
    clean_lowercase(value) -> Union{String, Missing}

Trim a value with `clean_text` and convert it to lowercase, so spelling
variants in casing compare equal. Used for the pickup and delivery country
and the transport mode. `missing` passes through.

# Examples
```julia
clean_lowercase("  GerMany ")   # "germany"
```
"""
function clean_lowercase(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end

    return lowercase(text)
end

"""
    clean_location(value) -> Union{String, Missing}

Normalize a city or distribution center name so it matches a key of
`location_ids`.

Steps: trim and lowercase the text, collapse repeated inner spaces, cut off a
trailing `" dc"` and remember it, translate known spelling variants
(e.g. Antwerpen, Anvers → antwerp; Böblingen → boeblingen; Singapur →
singapore; Mailand, Milano → milan; Warschau, Warszawa → warsaw), then add
`" dc"` back. Returns `missing` for an empty value.

# Examples
```julia
clean_location("Böblingen DC")       # "boeblingen dc"
clean_location("  Los   Angeles ")   # "los angeles"
```
"""
function clean_location(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end 

    normalized = lowercase(text)

    # Replacing repeated whitespaces with a single one 
    words = split(normalized)
    normalized = join(words, " ")

    # Check whether the provided city identifies as the destination 
    is_dc = endswith(normalized, " dc")

    if is_dc 
        # chop removes the last characters of a string, here further specified to fully remove " dc" 
        city = chop(normalized, tail=3)
    else 
        city = normalized 
    end 
    
    # Typical spelling variations and their standard english names 
    aliases = Dict(
        "böblingen" => "boeblingen",
        "boblingen" => "boeblingen",
        "singapur" => "singapore",
        "antwerpen" => "antwerp",
        "anvers" => "antwerp",
        "mailand" => "milan",
        "milano" => "milan",
        "warschau" => "warsaw",
        "warszawa" => "warsaw"
    )
    
    # Haskey: Determine whether a collection has a mapping for a given key
    if haskey(aliases, city)
        city = aliases[city]
    end 

    # Append " dc" after city normalization 
    if is_dc 
        return city * " dc"
    else 
        return city
    end 
end 
