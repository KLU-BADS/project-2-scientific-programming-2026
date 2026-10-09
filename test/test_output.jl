@testset "Output" begin
    if !isdefined(Project2, :all_together)
        @test_skip "output_creation.jl is not included in Project2 yet"
    else

        @testset "flagging" begin
            # Urgent (6) is critical.
            @test Project2.flagging(6) == :critical
            # Delivered late (8) has its own severity.
            @test Project2.flagging(8) == :late_arrival
            # At risk (5) needs watching.
            @test Project2.flagging(5) == :watch
            # An item without a status (skipped by main) needs watching and
            # must not crash the report.
            @test Project2.flagging(missing) == :watch
            # On time (4) and delivered on time (7) are ok.
            @test Project2.flagging(4) == :ok
            @test Project2.flagging(7) == :ok
        end

        @testset "icon_for" begin
            # Each severity has its own icon.
            @test Project2.icon_for(:critical) == "🚩"
            @test Project2.icon_for(:late_arrival) == "❌"
            @test Project2.icon_for(:watch) == "⚠️"
            @test Project2.icon_for(:ok) == "✓"
        end

        # Shared input for the three report-building functions:
        # three items in joined; main classified A and C and skipped B.
        joined = DataFrame(
            project_id = ["P-1", "P-1", "P-2"],
            shipment_id = ["S-1", "S-2", "S-3"],
            item_code = ["A", "B", "C"],
            material = ["M-1", "M-2", "M-3"],
        )
        row_collector = [("A", 4, Date(2026, 10, 20)), ("C", 8, Date(2026, 9, 1))]

        @testset "building_dataframe" begin
            item_details = Project2.building_dataframe(joined)
            # Keeps the four report columns from joined, under their report names.
            @test names(item_details) == ["Project_ID", "Shipment_ID", "Items_Number", "Material"]
            # One row per item of joined, in the same order.
            @test item_details.Items_Number == ["A", "B", "C"]
            @test item_details.Project_ID == ["P-1", "P-1", "P-2"]
        end

        @testset "building_small" begin
            results = Project2.building_small(row_collector)
            # Splits the (item_code, status, ETA) tuples into three columns.
            @test names(results) == ["Delivery_Status", "ETA", "Items_Number"]
            # One row per classified item: A and C, not B.
            @test results.Items_Number == ["A", "C"]
            @test results.Delivery_Status == [4, 8]
            @test results.ETA == [Date(2026, 10, 20), Date(2026, 9, 1)]
        end

        @testset "all_together" begin
            report = Project2.all_together(Project2.building_dataframe(joined),
                                           Project2.building_small(row_collector))
            # Every item of joined is in the report, once, in the same order.
            @test nrow(report) == 3
            @test report.Items_Number == ["A", "B", "C"]
            # Status and ETA come from row_collector; the skipped item B has none.
            @test isequal(report.Delivery_Status, [4, missing, 8])
            @test isequal(report.ETA, [Date(2026, 10, 20), missing, Date(2026, 9, 1)])
            # Each row gets a severity from flagging and an icon from icon_for:
            # A is on time (4), B has no status, C was delivered late (8).
            @test report.Severity == [:ok, :watch, :late_arrival]
            @test report.Icon == ["✓", "⚠️", "❌"]
        end

    end
end
