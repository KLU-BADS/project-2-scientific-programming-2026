# Integration: how the components work together, on the real data in data/.
# These tests don't check exact status counts: delivered/in transit depends on today's date, so counts change from day to day. They check the hand-overs between components instead.

@testset "Integration (real data)" begin

    # Data Loader -> everything else. Fails on Linux (GitHub Actions) while
    # data_io.jl asks for "internal_db.csv" / "scm_db.csv" in lowercase.
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
end
