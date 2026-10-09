using Project2
using Test
using Dates
using DataFrames

include("helpers.jl")

# Every @testset that fails is reported on its own, so the names say which
# component broken


@testset "Project2.jl" begin
    include("test_data_loader.jl")
    include("test_classification.jl")
    include("test_main_pipeline.jl")
    include("test_integration.jl")
end
