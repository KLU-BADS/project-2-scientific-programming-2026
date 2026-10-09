# Integration: how the components work together, on the real data in data/.

@testset "Integration (real data)" begin

    data = load_data()

    @testset "Data Loader: load_data on the real files" begin
        # Every order item is in the joined table once (1,177 items).
        @test nrow(data.joined) == 1177
        @test allunique(data.joined.item_code)
        # Every order item found its shipment (the join key matched).
        @test !any(ismissing, data.joined.shipment_id)
        # Every pickup and delivery city was turned into a location ID.
        @test !any(ismissing, data.joined.pickup_location_id)
        @test !any(ismissing, data.joined.delivery_location_id)
        # Both lane files have 13 origins x 4 DCs = 52 lanes.
        @test length(data.hub_lanes) == 52
        @test length(data.supplier_lanes) == 52
    end

    @testset "Data Loader -> Classification: lanes" begin
        # Every pickup/delivery pair in the data has a lane in both lookups,
        # so classify_hub and classify_pickup never hit a KeyError.
        location_pairs = Set(zip(data.joined.pickup_location_id, data.joined.delivery_location_id))
        @test all(pair -> haskey(data.hub_lanes, pair), location_pairs)
        @test all(pair -> haskey(data.supplier_lanes, pair), location_pairs)
        # Real lane values reach the classification functions correctly
        # (city names, DC headers and aliases all matched):
        # Rotterdam -> Leipzig DC by hub lane is 3 days,
        @test Project2.classify_hub(Date(2026, 10, 5), 7, 17, data.hub_lanes) == Date(2026, 10, 8)
        # Hamburg -> Hamburg DC by hub lane is 0 days,
        @test data.hub_lanes[(13, 14)].day == 0
        # Shanghai -> Hamburg DC from the supplier is 24 days.
        @test Project2.classify_pickup(Date(2026, 10, 1), 1, 14, data.supplier_lanes) == Date(2026, 10, 25)
    end

    row_collector, issues = build_report(data.joined, data.hub_lanes, data.supplier_lanes)

    @testset "Data Loader -> Classification -> Main: full loop" begin
        # Every active item is either classified or reported as an issue;
        # nothing disappears silently.
        @test length(row_collector) + length(issues) == count(==(true), data.joined.active)
        # Every status is one of the team's codes.
        @test all(entry -> entry[2] in (4, 5, 6, 7, 8), row_collector)
        # Each item appears at most once.
        @test allunique(first.(row_collector))
        # The summary adds up to the number of classified items.
        summary = summarize(row_collector)
        @test summary.total_items == length(row_collector)
        @test sum(values(summary.counts_by_status)) == summary.total_items
    end

    @testset "Main -> Output: row_collector format" begin
        # Each entry is exactly (item_code::String, status::Int, ETA::Date),
        # what Output reads with getindex.(row_collector, 1 / 2 / 3).
        @test all(entry -> entry isa Tuple{String, Int, Date}, row_collector)
    end

    @testset "Main -> Output: report on the real run" begin
        if !isdefined(Project2, :all_together)
            @test_skip "output_creation.jl is not included in Project2 yet"
        else
            report = Project2.all_together(Project2.building_dataframe(data.joined),
                                           Project2.building_small(row_collector))
            # One report row per item, in the order of joined.
            @test nrow(report) == nrow(data.joined)
            @test report.Items_Number == data.joined.item_code
            # Items main skipped are exactly the rows without a status.
            @test count(ismissing, report.Delivery_Status) == nrow(data.joined) - length(row_collector)
            # Every real row got a valid severity and an icon, including skipped ones.
            @test all(severity -> severity in (:critical, :late_arrival, :watch, :ok), report.Severity)
            @test !any(ismissing, report.Icon)
        end
    end

end
