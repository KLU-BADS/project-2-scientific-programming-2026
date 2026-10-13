using Dates

"""
    classify_delivered(required_delivery_date::Date, actual_delivery_date::Date) -> Int

Grade an item that has already been delivered against its requested
delivery date (RDD):

- `7` (delivered on time): delivered on or before the RDD
- `8` (delivered late): delivered after the RDD

Status codes used across the project: 1 already delivered, 2 at a hub,
3 at supplier, 4 on time, 5 at risk, 6 urgent, 7 delivered on time,
8 delivered late.

# Examples
```julia
classify_delivered(Date(2026, 9, 29), Date(2026, 9, 26))   # 7
```
"""
function classify_delivered(
    required_delivery_date::Date,
    actual_delivery_date::Date
)
    if actual_delivery_date > required_delivery_date
        return 8  # Delivered late
    else
        return 7  # Delivered on time
    end
end
