# Main pipeline: src/main.jl
# Tested with hand-made rows and the small lane lookups from helpers.jl,
# so these tests don't read any CSV file.

@testset "Main pipeline" begin

    @testset "status codes" begin
        # main.jl's names match the team's code list in classify_delivered.jl.
        # If someone renumbers a code, this shows it.
        @test (Project2.STAGE_DELIVERED, Project2.STAGE_AT_HUB, Project2.STAGE_AT_SUPPLIER) == (1, 2, 3)
        @test (Project2.STATUS_ON_TIME, Project2.STATUS_AT_RISK, Project2.STATUS_URGENT) == (4, 5, 6)
        @test (Project2.STATUS_DELIVERED_ON_TIME, Project2.STATUS_DELIVERED_LATE) == (7, 8)
    end

    @testset "classify_row: delivered" begin
        # Delivered before the RDD: stage 1, status 7, and the ETA shown in the report is the actual delivery date.
        result = classify_row(make_row(actual_delivery_date = TODAY - Day(10),
                                       requested_delivery_date = TODAY - Day(5)),
                              TEST_HUB_LANES, TEST_SUPPLIER_LANES)
        @test result == (stage = 1, status = 7, eta = TODAY - Day(10))

        # Delivered after the RDD: status 8.
        result = classify_row(make_row(actual_delivery_date = TODAY - Day(3),
                                       requested_delivery_date = TODAY - Day(10)),
                              TEST_HUB_LANES, TEST_SUPPLIER_LANES)
        @test result.status == 8
    end

    @testset "classify_row: at a hub" begin
        # Hub today, lane 3 days -> ETA in 3 days, RDD in 20 days -> on time.
        result = classify_row(make_row(hub_arrival_date = TODAY), TEST_HUB_LANES, TEST_SUPPLIER_LANES)
        @test result == (stage = 2, status = 4, eta = TODAY + Day(3))

        # A delivery date in the future doesn't count yet, so main follow determine_tracking_status and uses the hub branch.
        result = classify_row(make_row(actual_delivery_date = TODAY + Day(5),
                                       hub_arrival_date = TODAY - Day(1)),
                              TEST_HUB_LANES, TEST_SUPPLIER_LANES)
        @test result.stage == 2
        @test result.eta == TODAY + Day(2)
    end

    @testset "classify_row: at supplier" begin
        # Both pickup dates known: the actual one is used (activity diagram "pickupActual != empty?"). Lane 5 days -> ETA = actual + 5.
        result = classify_row(make_row(pickup_planned_date = TODAY, pickup_actual_date = TODAY + Day(2)),
                              TEST_HUB_LANES, TEST_SUPPLIER_LANES)
        @test result == (stage = 3, status = 4, eta = TODAY + Day(7))

        # Only the planned date known: the planned one is used.
        result = classify_row(make_row(pickup_planned_date = TODAY), TEST_HUB_LANES, TEST_SUPPLIER_LANES)
        @test result.eta == TODAY + Day(5)

        # No pickup date at all: the row can't be classified -> nothing.
        @test classify_row(make_row(), TEST_HUB_LANES, TEST_SUPPLIER_LANES) === nothing
    end

    @testset "classify_row: risk_interval and missing row" begin
        # ETA in 3 days, RDD in 4 days. With the default risk interval (2) that is at risk; with 0 it is on time. Shows the setting reaches shipment_delivery_status.
        row = make_row(hub_arrival_date = TODAY, requested_delivery_date = TODAY + Day(4))
        @test classify_row(row, TEST_HUB_LANES, TEST_SUPPLIER_LANES).status == 5
        @test classify_row(row, TEST_HUB_LANES, TEST_SUPPLIER_LANES; risk_interval = 0).status == 4

        # A missing row (stage 0) returns nothing instead of crashing.
        @test classify_row(missing, TEST_HUB_LANES, TEST_SUPPLIER_LANES) === nothing
    end

    @testset "build_report" begin
        # Seven rows: three that can be classified, one inactive and three that must be skipped with an issue.
        joined = DataFrame([
            make_row(item_code = "DEL", actual_delivery_date = TODAY - Day(10),
                     requested_delivery_date = TODAY - Day(5)),
            make_row(item_code = "HUB", hub_arrival_date = TODAY),
            make_row(item_code = "SUP", pickup_planned_date = TODAY,
                     pickup_location_id = 1, delivery_location_id = 14),
            make_row(item_code = "INACTIVE", active = false),
            make_row(item_code = "NO_RDD", requested_delivery_date = missing),
            make_row(item_code = "NO_LOC", pickup_location_id = missing),
            make_row(item_code = "NO_PICKUP"),
        ])
        row_collector, issues = build_report(joined, TEST_HUB_LANES, TEST_SUPPLIER_LANES)

        # row_collector holds exactly the classified rows, in table order, as (item_code, status, ETA): the format Output reads. SUP: Shanghai -> Hamburg DC 24 days, RDD in 20 days -> urgent (6).
        @test row_collector == [
            ("DEL", 7, TODAY - Day(10)),
            ("HUB", 4, TODAY + Day(3)),
            ("SUP", 6, TODAY + Day(24)),
        ]
        # The inactive row is left out without an issue; the other three skipped rows each get one issue naming the item.
        @test length(issues) == 3
        @test occursin("NO_RDD", issues[1])
        @test occursin("NO_LOC", issues[2])
        @test occursin("NO_PICKUP", issues[3])
    end

    @testset "summarize" begin
        row_collector = [("A", 4, TODAY), ("B", 6, TODAY), ("C", 6, TODAY), ("D", 8, TODAY)]
        summary = summarize(row_collector)
        # Counts every item and each status code.
        @test summary.total_items == 4
        @test summary.counts_by_status == Dict(4 => 1, 6 => 2, 8 => 1)
        # Immediate attention = urgent items (6) only.
        @test summary.immediate_attention_count == 2

        # An empty run gives zeros instead of an error.
        summary = summarize([])
        @test summary.total_items == 0
        @test summary.immediate_attention_count == 0
    end

end
