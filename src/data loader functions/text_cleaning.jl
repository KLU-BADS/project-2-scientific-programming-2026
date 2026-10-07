
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

function clean_lowercase(value)
    text = clean_text(value)

    if ismissing(text)
        return missing
    end

    return lowercase(text)
end

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