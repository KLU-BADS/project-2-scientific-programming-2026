# Project design

Describe the design of your project: its structure, what each component 
is responsible for, how the components interact, and how they work. Also describe the data required and the output that is generated.

UML diagrams provided in a `plantuml` block are automatically rendered when the
documentation is built. You can find the PlantUML documentation [here](https://plantuml.com/).

## Components

This package has one component named `hello` which provides a function `hello()`.

```plantuml
@startuml Item Tracking - Data Model

skinparam classAttributeIconSize 0
skinparam shadowing false
skinparam linetype ortho

skinparam class {
    BackgroundColor #FAFBFF
    BorderColor #2A5FC8
    HeaderBackgroundColor #1C2E
    HeaderFontColor #FFFFFF
    FontColor #18213A
    ArrowColor #2A5FC8
}
skinparam enum {
    BackgroundColor #ECFAF0
    BorderColor #2E8B3A
    HeaderBackgroundColor #1A4D28
    HeaderFontColor #FFFFFF
}

class OrderItem {
    +projectId : int
    +itemCode : str
    +material : str
    +quantity : int
    +kEUR : float
    +rdd : date
    +cdd : date
    +destinationDC : str
}

class Shipment {
    +shipmentId : int
    +mp1Reference : str
    +pickupCity : str
    +deliveryCity : str
    +carrierName : str
    +transportMode : str
    +leg1PickupPlanned : date
    +leg1PickupActual : date
    +leg1HubArrival : date
    +deliveryActual : date
}

class LanePickUpCity {
    +originCity : str
    +destinationDC : str
    +transitDays : int
}

class LaneHub {
    +originCity : str
    +destinationDC : str
    +transitDays : int
}

enum TrackingStage {
    DELIVERED
    AT_HUB
    PICKUP_PLANNED
}

enum DeliveryStatus {
    ON_TIME
    LATE
    ON_TRACK
    URGENT
    AT_RISK
}

class ItemClassification {
    +estimatedArrival : date
    +lastKnownStage : TrackingStage
    +status : DeliveryStatus
}

note right of TrackingStage
    DELIVERED      → compare deliveryActual vs rdd
    AT_HUB         → hubArrival + LaneHub matrix
    PICKUP_PLANNED → pickupPlanned + LanePickUpCity matrix
end note

Shipment "1" --> "1..*" OrderItem       : carries
Shipment      --> LanePickUpCity        : transit lookup
Shipment      --> LaneHub               : transit lookup
ItemClassification --> OrderItem        : classifies
ItemClassification --> TrackingStage    : stage
ItemClassification --> DeliveryStatus   : status

@enduml
```


## Behaviour

The `hello()` function prints "Hello World".

```plantuml
@startuml
left to right direction
(*) --> "print"
"print" --> (*)
@enduml
```
