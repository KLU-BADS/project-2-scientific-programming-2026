"""
    Project2

Classifies supply chain order items by delivery status, combining the
internal order database with SCM shipment data and two lane transit
matrices. See the docs (design.md) for the full data model and
classification logic.
"""
module Project2

# Packages used throughout the program
using CSV
using DataFrames
using Dates

# Data Loader
include(joinpath("data loader functions", "text_cleaning.jl"))
include(joinpath("data loader functions", "value_parser.jl"))
include(joinpath("data loader functions", "table_cleaning.jl"))
include(joinpath("data loader functions", "locations.jl"))
include(joinpath("data loader functions", "lanes.jl"))
include(joinpath("data loader functions", "data_io.jl"))

# Classification
include(joinpath("classification functions", "determine_tracking_status.jl"))
include(joinpath("classification functions", "classify_delivered.jl"))
include(joinpath("classification functions", "classify_hub.jl"))
include(joinpath("classification functions", "classify_pickup.jl"))
include(joinpath("classification functions", "shipment_delivery_status.jl"))

# Output
# Uncomment once output_creation.jl is merged into the repo.
# include("output_creation.jl")

# Main pipeline
include("main.jl")

# Functions to be exported
export main, load_data, build_report, classify_row, summarize

end # module Project2
