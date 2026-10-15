"""
    shipment_delivery_status(estimated_time_of_arrival::Date, requested_delivery_date::Date, risk_interval::Int) -> Int

Grade a shipment that is still in transit by comparing its ETA with the
requested delivery date (RDD), with a tolerance of `risk_interval` days on
each side:

- `4` (on time): ETA on or before RDD − `risk_interval`
- `6` (urgent): ETA on or after RDD + `risk_interval`
- `5` (at risk): anything in between

With `risk_interval = 0` there is no at-risk window.

# Examples
```julia
shipment_delivery_status(Date(2026, 10, 12), Date(2026, 10, 12), 2)   # 5
```
"""
function shipment_delivery_status(estimated_time_of_arrival::Date, requested_delivery_date::Date, risk_interval::Int)
    if estimated_time_of_arrival <= requested_delivery_date - Day(risk_interval)
        return 4 #on time
    elseif estimated_time_of_arrival >= requested_delivery_date + Day(risk_interval)
        return 6 #urgent
    else
        return 5 #at risk
    end

end

