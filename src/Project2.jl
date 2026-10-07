"""
    Project2

A minimal Julia package to start a project from.
"""
module Project2

# Adding modules used throughout the program  
using CSV 
using DataFrames
using Dates

# Files to be included
include("hello.jl")

# Functions to be exported
export hello

end # module Project2
