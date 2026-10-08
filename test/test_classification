# Classification: src/classification functions/
# Each function is tested alone, with hand-made rows, dates and lanes.

@testset "Classification" begin

    @testset "determine_tracking_status" begin
        # Delivery date in the past -> 1 (already delivered).
        @test Project2.determine_tracking_status(make_row(actual_delivery_date = TODAY - Day(10))) == 1
        # Only a hub arrival date -> 2 (at a hub).
        @test Project2.determine_tracking_status(make_row(hub_arrival_date = TODAY - Day(2))) == 2
        # No delivery date and no hub date -> 3 (at supplier).
        @test Project2.determine_tracking_status(make_row()) == 3
        # Delivered and also a hub date -> 1: delivery is checked first, as in the activity diagram.
        @test Project2.determine_tracking_status(make_row(actual_delivery_date = TODAY - Day(10),
                                                 hub_arrival_date = TODAY - Day(15))) == 1
        # Boundary: a delivery date of today is not "before today", so the item is not delivered yet (here: no hub date -> 3).
        @test Project2.determine_tracking_status(make_row(actual_delivery_date = TODAY)) == 3
        # A delivery date in the future is ignored; the hub date decides -> 2.
        @test Project2.determine_tracking_status(make_row(actual_delivery_date = TODAY + Day(5),
                                                 hub_arrival_date = TODAY - Day(1))) == 2
        # A missing row returns 0 instead of crashing.
        @test Project2.determine_tracking_status(missing) == 0
    end

    @testset "classify_hub" begin
        # ETA = hub arrival + transit days of the lane (Rotterdam -> Leipzig DC, 3).
        @test Project2.classify_hub(Date(2026, 10, 5), 7, 17, TEST_HUB_LANES) == Date(2026, 10, 8)
        # The result is a Date, so it can be compared with the RDD.
        @test Project2.classify_hub(Date(2026, 10, 5), 7, 17, TEST_HUB_LANES) isa Date
        # A 0-day lane (Hamburg -> Hamburg DC) gives the hub date itself.
        @test Project2.classify_hub(Date(2026, 10, 5), 13, 14, TEST_HUB_LANES) == Date(2026, 10, 5)
        # Adding days crosses month and year correctly.
        @test Project2.classify_hub(Date(2026, 12, 30), 7, 17, TEST_HUB_LANES) == Date(2027, 1, 2)
        # A pair that is not in the hub lanes raises KeyError.
        @test_throws KeyError Project2.classify_hub(Date(2026, 10, 5), 1, 14, TEST_HUB_LANES)
    end

    @testset "classify_pickup" begin
        # ETA = pickup date + transit days of the lane (Shanghai -> Hamburg DC, 24).
        @test Project2.classify_pickup(Date(2026, 10, 1), 1, 14, TEST_SUPPLIER_LANES) == Date(2026, 10, 25)
        # The result is a Date (not a status code).
        @test Project2.classify_pickup(Date(2026, 10, 1), 1, 14, TEST_SUPPLIER_LANES) isa Date
        # A 0-day lane gives the pickup date itself.
        zero_lane = Dict((13, 14) => Project2.Lane(13, 14, 0))
        @test Project2.classify_pickup(Date(2026, 10, 1), 13, 14, zero_lane) == Date(2026, 10, 1)
        # Leap year: 5 days after 27 Feb 2028 passes through 29 Feb.
        @test Project2.classify_pickup(Date(2028, 2, 27), 7, 17, TEST_SUPPLIER_LANES) == Date(2028, 3, 3)
        # A pair that is not in the supplier lanes raises KeyError.
        @test_throws KeyError Project2.classify_pickup(Date(2026, 10, 1), 8, 17, TEST_SUPPLIER_LANES)
    end

    @testset "classify_delivery" begin
        # Arguments: (required delivery date, actual delivery date).
        # Delivered before the RDD -> 7 (delivered on time).
        @test Project2.classify_delivery(Date(2026, 10, 15), Date(2026, 10, 10)) == 7
        # Boundary: delivered on the RDD itself still counts as on time.
        @test Project2.classify_delivery(Date(2026, 10, 15), Date(2026, 10, 15)) == 7
        # Boundary: one day after the RDD -> 8 (delivered late).
        @test Project2.classify_delivery(Date(2026, 10, 15), Date(2026, 10, 16)) == 8
        # Clearly late -> 8.
        @test Project2.classify_delivery(Date(2026, 10, 15), Date(2026, 11, 1)) == 8
    end

    @testset "shipment_delivery_status" begin
        # RDD 15 Oct 2026, risk interval 2 days unless stated:
        # on time if ETA <= 13 Oct, urgent if ETA >= 17 Oct, at risk between.
        requested_delivery_date = Date(2026, 10, 15)
        # Well before -> 4 (on time).
        @test Project2.shipment_delivery_status(Date(2026, 10, 8), requested_delivery_date, 2) == 4
        # Boundary: exactly RDD - 2 is still on time.
        @test Project2.shipment_delivery_status(Date(2026, 10, 13), requested_delivery_date, 2) == 4
        # Just inside the window -> 5 (at risk).
        @test Project2.shipment_delivery_status(Date(2026, 10, 14), requested_delivery_date, 2) == 5
        # On the RDD -> at risk.
        @test Project2.shipment_delivery_status(Date(2026, 10, 15), requested_delivery_date, 2) == 5
        # One day after the RDD is still inside the window -> at risk.
        @test Project2.shipment_delivery_status(Date(2026, 10, 16), requested_delivery_date, 2) == 5
        # Boundary: exactly RDD + 2 -> 6 (urgent).
        @test Project2.shipment_delivery_status(Date(2026, 10, 17), requested_delivery_date, 2) == 6
        # Well after -> urgent.
        @test Project2.shipment_delivery_status(Date(2026, 10, 23), requested_delivery_date, 2) == 6
        # Risk interval 0 (no window): on the RDD is on time ...
        @test Project2.shipment_delivery_status(Date(2026, 10, 15), requested_delivery_date, 0) == 4
        # ... and one day late is urgent.
        @test Project2.shipment_delivery_status(Date(2026, 10, 16), requested_delivery_date, 0) == 6
    end

end
