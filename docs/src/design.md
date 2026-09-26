# Project design

The project is structured around six components: four data classes that represent the input and lookup data, one classification class that holds the output, and two enumerations that constrain the possible values of the classification result.

UML diagrams provided in a `plantuml` block are automatically rendered when the
documentation is built. You can find the PlantUML documentation [here](https://plantuml.com/).

---

# Components (Class Diagram)

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

## Components and responsibilities

OrderItem represents a single line item from the internal order management database. It holds the item's identity, quantity, financial value, destination distribution centre, and the two key dates the programme works against: the Required Delivery Date (RDD) and the Customer Desired Date (CDD). Each order item is the primary unit being tracked.

Shipment represents the logistics record from the external SCM system. It captures where an item is being collected from, where it is going, and the three milestone dates that record how far along in transit the shipment has progressed: the planned pickup date, the actual pickup date, the hub arrival date, and the actual delivery date.

LanePickUpCity is a lookup table that maps origin cities to destination distribution centers with an associated transit time in days. It is used when the last known milestone is the planned pickup date, meaning the item has not yet been collected and the full journey time must be estimated.

LaneHub is a second lookup table with the same structure, used when the item has already arrived at an intermediate hub. In this case only the remaining leg, from the hub to the destination distribution center, needs to be estimated, and this matrix provides that transit time.

ItemClassification is the output produced for each order item after the programme has determined its tracking stage and run the appropriate calculation. It stores the estimated or actual arrival date, the stage at which the item was found, and the resulting delivery status.

The enumerations TrackingStage and DeliveryStatus constrain the possible outcomes. TrackingStage has three values: DELIVERED, AT_HUB, and PICKUP_PLANNED, corresponding to the three branches of the classification logic. DeliveryStatus has five values: ON_TIME and LATE apply only to delivered items, while ON_TRACK, URGENT, and AT_RISK apply to items still in transit.

## Components and responsibilities

The program begins by joining each OrderItem to its corresponding Shipment via the projectID. Once joined, it inspects the shipment's milestone dates in order of priority to determine the TrackingStage. If a delivery actual date is present, the stage is DELIVERED and the actual date is compared directly against the RDD. If only a hub arrival date is available, the stage is AT_HUB and the LaneHub matrix is used to estimate the remaining transit time. If only a planned pickup date is available, the stage is PICKUP_PLANNED and the LanePickUpCity matrix is used to estimate the full journey. In all cases the result is written into an ItemClassification record for that item.

## Data Required

The programme requires four input sources: the internal order database containing the OrderItem records, the SCM extract containing the Shipment records, and the two lane transit matrices (LanePickUpCity and LaneHub) provided as lookup sheets.

## Outputs

The program produces an array with the project identification number, shipment identification number, and item number, in which every item has an assigned delivery status, an estimated date of arrival, and the tracking stage based on the classification. It also provides a summary of all active shipments, their delivery states, as well as the amount of shipments requiring immediate attention.

---

# Components (Activity Diagram)

```plantuml
@startuml
title Activity - Delivery Status

skinparam shadowing false
skinparam defaultFontName SansSerif
skinparam ActivityBackgroundColor #dae8fc
skinparam ActivityBorderColor #6c8ebf
skinparam ActivityDiamondBackgroundColor #fff2cc
skinparam ActivityDiamondBorderColor #d6b656
skinparam ArrowColor #333333
skinparam ActivityStartColor #000000
skinparam ActivityEndColor #000000

start

:Init
(load & check data);

repeat
  :Read ShipID;

  if (delActual < Today?) then (yes)
    if (RDD < delActual?) then (yes)
      :delStatus = late;
    else (no)
      :delStatus = onTime;
    endif
  else (no)
    if (hubArrival != empty?) then (yes)
      :Calc ETA (hub);
    else (no)
      if (pickupActual != empty?) then (yes)
        :Calc ETA (pickupActual);
      else (no)
        :Calc ETA (pickupPlanned);
      endif
    endif

    switch (ETA <= RDD?)
    case (yes, outside\nrisk interval)
      :delStatus = onTime;
    case (inside\nrisk interval)
      :delStatus = atRisk;
    case (no, outside\nrisk interval)
      :delStatus = urgent;
    endswitch
  endif

  :Update delStatus;
  :Update output matrix;
repeat while (Shipment left?) is (yes) not (no)

:Create report;

stop
@enduml
```

---

# Entity Relationship Diagram (ERD)

```plantuml
@startuml

left to right direction
hide circle
hide methods

skinparam backgroundColor #FFFFFF
skinparam shadowing false
skinparam roundcorner 0
skinparam defaultFontName Arial
skinparam defaultFontSize 13
skinparam classAttributeIconSize 0

skinparam class {
    BackgroundColor #FFFFFF
    HeaderBackgroundColor #000000
    BorderColor #94A3B8
    BorderThickness 1
    AttributeFontColor #0F172A
}

skinparam ArrowColor #64748B
skinparam ArrowThickness 1
skinparam ArrowFontColor #0F172A

class "<color:white>Internal DB</color>" as internal {
    Active
    --
    Business Unit
    --
    Material
    --
    Item Code [PK]
    --
    Quantity
    --
    Destination Hub
    --
    Project ID
    --
    Project Chapter ID
    --
    k EUR
    --
    RDD
    --
    CDD
}

class "<color:white>SCM DB</color>" as scm {
    Project ID MP1 Reference
    --
    Shipment ID
    --
    Sub shipment, delivery line, product code [Join key]
    --
    Sub shipment, delivery line, description
    --
    Sub shipment, delivery line, Quantity picked
    --
    Pickup city
    --
    Pickup country
    --
    Delivery city
    --
    Delivery country
    --
    {field} Leg 1, Pickup Planned (date)
    --
    {field} Leg 1, Pickup Actual (date)
    --
    {field} Leg 1, Hub Arrival (date)
    --
    {field} Leg n, Delivery Actual (date)
    --
    Leg n, Transport Mode
    --
    Leg 1, Carrier Name
}

internal::Item "1" -- "1" scm::product

@enduml
```