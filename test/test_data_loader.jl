# Data Loader: src/data loader functions/
# Each function is tested on small hand-made values or tables.

@testset "Data Loader" begin

    @testset "clean_text" begin
        # Removes spaces around the value.
        @test Project2.clean_text("  ITEM-1  ") == "ITEM-1"
        # Returns a plain String (not a SubString), so later code gets one type.
        @test Project2.clean_text(" a ") isa String
        # An empty or blank cell becomes missing instead of "".
        @test ismissing(Project2.clean_text("   "))
        # A missing cell stays missing instead of crashing in strip().
        @test ismissing(Project2.clean_text(missing))
    end

    @testset "clean_lowercase" begin
        # Trims and lowercases, e.g. "Germany" and "germany " end up equal.
        @test Project2.clean_lowercase("  GerMany ") == "germany"
        # Missing passes through.
        @test ismissing(Project2.clean_lowercase(missing))
    end

    @testset "clean_location" begin
        # Lowercases a DC name and keeps the " dc" ending.
        @test Project2.clean_location("Hamburg DC") == "hamburg dc"
        # Collapses repeated spaces inside a name.
        @test Project2.clean_location("  Los   Angeles ") == "los angeles"
        # Translates spelling variants to the standard name.
        @test Project2.clean_location("Antwerpen") == "antwerp"
        @test Project2.clean_location("Singapur") == "singapore"
        # Translates a variant that is also a DC: the alias is applied to the
        # city part and " dc" is added back.
        @test Project2.clean_location("Böblingen DC") == "boeblingen dc"
        # Empty cell becomes missing.
        @test ismissing(Project2.clean_location(""))
    end

    @testset "parse_lane_days" begin
        # Turns a lane cell into a whole number of days.
        @test Project2.parse_lane_days("12") == 12
        @test Project2.parse_lane_days(" 3 ") == 3
        # Empty cell becomes missing.
        @test ismissing(Project2.parse_lane_days(""))
        # Text, decimals and negative days are rejected with a clear error.
        @test_throws ArgumentError Project2.parse_lane_days("abc")
        @test_throws ArgumentError Project2.parse_lane_days("1.5")
        @test_throws ArgumentError Project2.parse_lane_days("-1")
    end

    @testset "parse_delivery_date" begin
        # European format day.month.year.
        @test Project2.parse_delivery_date("27.09.2026") == Date(2026, 9, 27)
        # Day and month with one digit (the format allows 1 or 2 digits).
        @test Project2.parse_delivery_date("1.2.2026") == Date(2026, 2, 1)
        # ISO format year-month-day.
        @test Project2.parse_delivery_date("2026-09-27") == Date(2026, 9, 27)
        # A time after the date is ignored.
        @test Project2.parse_delivery_date("2026-09-29 00:00:00") == Date(2026, 9, 29)
        # Empty and missing cells become missing.
        @test ismissing(Project2.parse_delivery_date(""))
        @test ismissing(Project2.parse_delivery_date(missing))
        # Any other format is rejected instead of being guessed.
        @test_throws ArgumentError Project2.parse_delivery_date("2026/09/27")
    end

    @testset "parse_quantity" begin
        # American number format with thousands separator.
        @test Project2.parse_quantity("1,234.50") == 1234.5
        # Plain whole number and leading plus sign.
        @test Project2.parse_quantity("89") == 89.0
        @test Project2.parse_quantity("+12") == 12.0
        # Always returns a Float64.
        @test Project2.parse_quantity("89") isa Float64
        # European format is rejected instead of being read wrongly.
        @test_throws ArgumentError Project2.parse_quantity("1.234,50")
        # Negative numbers are rejected by the current pattern (the code
        # comment says -12 is allowed; the team should decide which is right).
        @test_throws ArgumentError Project2.parse_quantity("-12")
        # Empty cell becomes missing.
        @test ismissing(Project2.parse_quantity(""))
    end

    @testset "parse_active" begin
        # Yes/no in any casing becomes true/false.
        @test Project2.parse_active("Yes") === true
        @test Project2.parse_active(" no ") === false
        # Anything else is rejected.
        @test_throws ArgumentError Project2.parse_active("maybe")
        # Empty cell becomes missing.
        @test ismissing(Project2.parse_active(""))
    end

    @testset "convert_column!" begin
        # Applies a converter to every value of one column.
        table = DataFrame(answer = [" yes", "no "])
        Project2.convert_column!(table, :answer, Project2.parse_active)
        @test table.answer == [true, false]

        # When one value fails, the error names the column and the row, so a bad cell in a 1,177-row file can be found.
        table = DataFrame(active = ["yes", "maybe"])
        caught_error = try
            Project2.convert_column!(table, :active, Project2.parse_active)
            nothing
        catch exception
            exception
        end
        @test caught_error isa ErrorException
        @test occursin("Column 'active', data row '2'", sprint(showerror, caught_error))
    end

    @testset "clean_internal" begin
        # A small raw table shaped like Internal_db.csv (all values text, as read_table delivers them), including one extra column.
        raw_table = DataFrame(
            "Active" => ["Yes", "no"],
            "Business Unit" => ["IGT", "IGT"],
            "Material" => ["M-1", "M-2"],
            "Item Code" => [" ITEM-1 ", "ITEM-2"],
            "Quantity" => ["1,234.50", "2"],
            "Destination Hub" => ["X", "Y"],
            "Project ID" => ["P-1", "P-2"],
            "k EUR" => ["10", "20.5"],
            "RDD" => ["27.09.2026", "2026-10-01"],
            "CDD" => ["2026-09-25 00:00:00", missing],
        )
        internal = Project2.clean_internal(raw_table)

        # Keeps only the needed columns and gives them the names the rest of the program uses (RDD -> requested_delivery_date, CDD -> actual_delivery_date).
        @test names(internal) == ["active", "business_unit", "material", "item_code", "quantity",
                                  "project_id", "k_eur", "requested_delivery_date", "actual_delivery_date"]
        # Each column gets its proper type.
        @test internal.active == [true, false]
        @test internal.item_code == ["ITEM-1", "ITEM-2"]
        @test internal.quantity == [1234.5, 2.0]
        @test internal.k_eur == [10.0, 20.5]
        @test internal.requested_delivery_date == [Date(2026, 9, 27), Date(2026, 10, 1)]
        @test internal.actual_delivery_date[1] == Date(2026, 9, 25)
        # An empty CDD stays missing (item not delivered yet).
        @test ismissing(internal.actual_delivery_date[2])
    end

    @testset "clean_scm" begin
        # A one-row raw table shaped like SCM_db.csv.
        raw_table = DataFrame(
            "Project ID MP1 Reference" => ["P-1"],
            "Shipment ID" => ["S-1"],
            "Sub shipment, delivery line, product code" => ["ITEM-1"],
            "Pickup city" => ["  Antwerpen "],
            "Pickup country" => ["Belgium"],
            "Delivery city" => ["Leipzig DC"],
            "Delivery country" => ["Germany"],
            "Leg 1, Pickup Planned (date)" => ["01.09.2026"],
            "Leg 1, Pickup Actual (date)" => ["2026-09-02"],
            "Leg 1, Hub Arrival (date)" => [missing],
            "Leg n, Delivery Actual (date)" => [missing],
            "Leg n, Transport Mode" => ["Truck"],
            "Leg 1, Carrier Name" => ["DHL"],
        )
        shipments = Project2.clean_scm(raw_table)

        # The join key column exists under its new name.
        @test "product_code" in names(shipments)
        # Cities are normalized the same way the location IDs expect.
        @test shipments.pickup_city == ["antwerp"]
        @test shipments.delivery_city == ["leipzig dc"]
        # Countries and transport mode are lowercased; the carrier is not.
        @test shipments.pickup_country == ["belgium"]
        @test shipments.transport_mode == ["truck"]
        @test shipments.carrier_name == ["DHL"]
        # Both date formats are parsed; an empty hub date stays missing.
        @test shipments.pickup_planned_date == [Date(2026, 9, 1)]
        @test shipments.pickup_actual_date == [Date(2026, 9, 2)]
        @test ismissing(shipments.hub_arrival_date[1])
    end

    @testset "clean_lane_matrix" begin
        # A 2 x 2 lane matrix shaped like the lane CSVs.
        raw_table = DataFrame(
            "Origin city / Distribution Center" => ["Shanghai", "Rotterdam"],
            "Hamburg DC" => ["24", "2"],
            "Leipzig DC" => ["25", "3"],
        )
        matrix = Project2.clean_lane_matrix(raw_table)

        # Origin cities in the first column are normalized.
        @test matrix[!, 1] == ["shanghai", "rotterdam"]
        # Destination column headers are normalized too.
        @test names(matrix)[2:end] == ["hamburg dc", "leipzig dc"]
        # Day values become integers.
        @test matrix[!, "hamburg dc"] == [24, 2]
    end

    @testset "location_id" begin
        # Known names map to their numeric ID, after cleaning.
        @test Project2.location_id("Hamburg DC", Project2.location_ids) == 14
        @test Project2.location_id("  rotterdam ", Project2.location_ids) == 7
        @test Project2.location_id("Antwerpen", Project2.location_ids) == 8
        # Missing stays missing.
        @test ismissing(Project2.location_id(missing, Project2.location_ids))
        # An unknown city stops the program with an error instead of getting a wrong ID.
        @test_throws ErrorException Project2.location_id("Paris", Project2.location_ids)
        # The lookup has 17 locations with the IDs 1 to 17, each used once.
        @test sort(collect(values(Project2.location_ids))) == 1:17
    end

    @testset "add_location_ids!" begin
        # Adds pickup and delivery ID columns next to the city names.
        shipments = DataFrame(
            pickup_city = Union{Missing, String}["shanghai", missing],
            delivery_city = ["hamburg dc", "leipzig dc"],
        )
        Project2.add_location_ids!(shipments, Project2.location_ids)
        @test isequal(shipments.pickup_location_id, [1, missing])
        @test shipments.delivery_location_id == [14, 17]
    end

    @testset "build_lane_lookup / lanes_to_dataframe" begin
        matrix = Project2.clean_lane_matrix(DataFrame(
            "Origin city / Distribution Center" => ["Shanghai", "Rotterdam"],
            "Hamburg DC" => ["24", "2"],
            "Leipzig DC" => ["25", "3"],
        ))
        lanes = Project2.build_lane_lookup(matrix, Project2.location_ids)

        # One entry per origin-destination pair: 2 origins x 2 DCs.
        @test length(lanes) == 4
        # Keys are (origin ID, destination ID); values hold the days.
        @test lanes[(1, 14)] == Project2.Lane(1, 14, 24)
        @test lanes[(7, 17)].day == 3

        # Turning the lookup back into a table gives one row per lane, sorted by origin and destination.
        table = Project2.lanes_to_dataframe(lanes)
        @test nrow(table) == 4
        @test (table.origin_id[1], table.destination_id[1], table.day[1]) == (1, 14, 24)
    end

    @testset "read_table / export_tables" begin
        mktempdir() do folder
            # A missing file stops with a clear error naming the path.
            @test_throws ArgumentError Project2.read_table(folder, "does_not_exist.csv")

            # Every value is read as text; empty cells become missing.
            write(joinpath(folder, "small.csv"), "item_code,material\nITEM-1,M-1\nITEM-2,\n")
            small_table = Project2.read_table(folder, "small.csv")
            @test small_table.item_code == ["ITEM-1", "ITEM-2"]
            @test ismissing(small_table.material[2])

            # export_tables creates the output folder and writes three CSVs.
            output_folder = joinpath(folder, "out")
            Project2.export_tables(DataFrame(item_code = ["ITEM-1"]), TEST_HUB_LANES, TEST_SUPPLIER_LANES, output_folder)
            @test isfile(joinpath(output_folder, "joined.csv"))
            @test isfile(joinpath(output_folder, "hub_lanes.csv"))
            @test isfile(joinpath(output_folder, "supplier_lanes.csv"))
        end
    end

end
