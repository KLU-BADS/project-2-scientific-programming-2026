# Project design

Project2 is implemented as a functional Julia module that loads CSV files into
DataFrames, cleans and joins the input tables, classifies active order items,
and builds a report. The diagrams below describe the current implementation,
including its numeric stage and delivery-status codes.

UML diagrams provided in a `plantuml` block are automatically rendered when the
documentation is built. You can find the PlantUML documentation [here](https://plantuml.com/).

---

# Components (Implementation Diagram)

```plantuml
@startuml Project2 Implementation Components

skinparam shadowing false
skinparam componentStyle rectangle
skinparam linetype ortho

component "Project2 module\n(main.jl)" as module {
    [main]
    [load_data]
    [build_report]
    [classify_row]
    [summarize]
}

component "Data loading\n(data_io.jl,\ntable_cleaning.jl)" as loading
component "Location and lane\nlookups\n(locations.jl, lanes.jl)" as lookups
component "Classification functions\n(determine_tracking_status.jl,\nclassify_*.jl,\nshipment_delivery_status.jl)" as classification
component "Report creation\n(output_creation.jl)" as output
database "Four CSV inputs\nInternal_db.csv\nSCM_db.csv\nlm_supplier_dc.csv\nlm_logistics_dc.csv" as csv
collections "DataFrames and lookups\njoined::DataFrame\nhub_lanes::Dict\nsupplier_lanes::Dict" as data
collections "Classified rows\n(item_code, status, ETA)\nplus issues" as classified
collections "Report DataFrame\nCSV export" as report

csv --> loading
loading --> lookups : cleaned locations\nand lane matrices
loading --> data : left-joined rows
lookups --> data : location IDs\nand lane dictionaries
module --> loading : load_data
module --> classification : classify_row / build_report
data --> module
classification --> classified
module --> classified
classified --> output
data --> output : report identifiers\nand material
output --> report

note right of classification
  Lane is the concrete struct:
  (origin_id, destination_id, day)

  Stage codes:
  0 missing row, 1 delivered,
  2 at hub, 3 at supplier

  Status codes:
  4 on time, 5 at risk,
  6 urgent, 7 delivered on time,
  8 delivered late
end note

@enduml
```

## Components and responsibilities

`load_data` reads four CSV files, cleans the internal and SCM tables, left-joins
them on `item_code` to `product_code`, adds location IDs, and builds supplier and
hub lane dictionaries. Each lane dictionary is keyed by an
`(origin_id, destination_id)` tuple and stores `Lane` values.

`build_report` processes active joined rows, skipping rows with a missing
requested delivery date or location IDs and recording those skips as issues.
`classify_row` selects a tracking stage, calculates an ETA, and returns a named
tuple `(stage, status, eta)`. `build_report` collects successful classifications
as `(item_code, status, eta)` tuples. Stage and delivery status values are
integer codes, not Julia enum types.

`main` summarizes the collected statuses and creates the report by joining
classified status/ETA values back to the project, shipment, item, and material
columns. It logs skipped-row issues, displays the report, exports it as CSV,
and returns the report, summary, and issues.

> **Current implementation detail:** `clean_internal` maps the internal `CDD`
> column to `actual_delivery_date`; `clean_scm` maps SCM `Leg n, Delivery
> Actual (date)` to `scm_actual_delivery_date`. The current stage detector and
> delivered-item classifier read `actual_delivery_date`, not
> `scm_actual_delivery_date`. Consequently, as currently implemented, the
> delivered branch uses the internal CDD value. This is reflected in the
> activity and data diagrams below.

---

# Activity Diagram (Classification and Report Flow)

```plantuml
@startuml
title Project2 - Current Classification and Report Flow

skinparam shadowing false
skinparam defaultFontName SansSerif
skinparam ActivityBackgroundColor #dae8fc
skinparam ActivityBorderColor #6c8ebf
skinparam ActivityDiamondBackgroundColor #fff2cc
skinparam ActivityDiamondBorderColor #d6b656
skinparam ArrowColor #333333

start
:Read four CSV inputs;
:Clean internal, SCM,\nand lane tables;
:Left-join internal to SCM\n(item_code = product_code);
:Add location IDs and build\nsupplier/hub lane dictionaries;

while (Joined rows remain?) is (yes)
  :Read next joined row;
  if (active === true?) then (no)
    :Ignore inactive row;
  else (yes)
    if (RDD missing?) then (yes)
      :Record issue and skip row;
    else (no)
      if (pickup or delivery\nlocation ID missing?) then (yes)
        :Record issue and skip row;
      else (no)
        if (actual_delivery_date exists\nand is before today?) then (yes)
          :Stage = 1 (delivered);\nETA = actual_delivery_date;
          if (ETA > RDD?) then (yes)
            :Status = 8 (delivered late);
          else (no)
            :Status = 7 (delivered on time);
          endif
        else (no)
          if (hub_arrival_date exists?) then (yes)
            :Stage = 2 (at hub);\nETA = hub_arrival_date\n+ hub lane days;
          else (no)
            :Stage = 3 (at supplier);\nUse pickup_actual_date,\nelse pickup_planned_date;
            if (pickup date missing?) then (yes)
              :Record issue and skip row;
            else (no)
              :ETA = pickup date\n+ supplier lane days;
            endif
          endif
          if (ETA was calculated?) then (yes)
            if (ETA <= RDD - risk_interval?) then (yes)
              :Status = 4 (on time);
            else (no)
              if (ETA >= RDD + risk_interval?) then (yes)
                :Status = 6 (urgent);
              else (no)
                :Status = 5 (at risk);
              endif
            endif
          endif
        endif
        if (classification exists?) then (yes)
          :Collect (item_code, status, ETA);
        endif
      endif
    endif
  endif
endwhile (no)

:Warn for collected issues;
:Summarize classified statuses\nand urgent count;
:Build report and join status/ETA\nback on Items_Number;
:Add severity and icon;
:Display report and export CSV;
:Return report, summary, and issues;
stop

note right
  actual_delivery_date is the cleaned internal CDD column.
  The SCM delivery date is stored as scm_actual_delivery_date
  and is not read by the current classifier.
end note
@enduml
```

---

# Entity Relationship Diagram (Input and Output Data)

```plantuml
@startuml Project2 Data Relationships

left to right direction
hide circle
hide methods
skinparam shadowing false
skinparam classAttributeIconSize 0

skinparam class {
    BackgroundColor #FFFFFF
    HeaderBackgroundColor #1C2E
    HeaderFontColor #FFFFFF
    BorderColor #2A5FC8
    AttributeFontColor #18213A
}
skinparam ArrowColor #64748B
skinparam ArrowFontColor #0F172A

entity "Internal DataFrame\n(clean_internal)" as internal {
    * item_code : String <<join key>>
    --
    active : Bool
    project_id : String
    material : String
    quantity : number
    k_eur : number
    requested_delivery_date : Date
    actual_delivery_date : Date <<source: CDD>>
}

entity "SCM DataFrame\n(clean_scm)" as scm {
    * product_code : String <<join key>>
    --
    shipment_id : String
    pickup_city : String
    delivery_city : String
    pickup_planned_date : Date
    pickup_actual_date : Date
    hub_arrival_date : Date
    scm_actual_delivery_date : Date
    transport_mode : String
    carrier_name : String
}

entity "Joined DataFrame\n(leftjoin)" as joined {
    item_code
    project_id
    shipment_id
    material
    requested_delivery_date
    actual_delivery_date
    scm_actual_delivery_date
    pickup/delivery location IDs
    milestone dates
}

entity "Supplier lane lookup\nDict{Tuple, Lane}" as supplier {
    * (origin_id, destination_id) : key
    --
    day : Int
}

entity "Hub lane lookup\nDict{Tuple, Lane}" as hub {
    * (origin_id, destination_id) : key
    --
    day : Int
}

entity "Classified rows\nVector of tuples" as results {
    item_code : String
    status : Int
    ETA : Date
}

entity "Report DataFrame" as report {
    project_id
    shipment_id
    Items_Number
    Material
    Delivery_Status
    ETA
    Severity
    Icon
}

internal }o--o{ scm : "leftjoin: item_code = product_code\n(no key constraint enforced)"
internal ||--o{ joined : contributes rows
scm }o--|| joined : contributes shipment data
joined }o--o{ supplier : "pickup location +\ndelivery location"
joined }o--o{ hub : "pickup location +\ndelivery location"
joined ||--o{ results : active rows that\npass checks and classify
joined ||--o{ report : identifiers\nand material
results }o--o{ report : "leftjoin on item_code /\nItems_Number"

note bottom of results
  Stage is returned by classify_row but not stored
  in the collected output or final report.
  Status codes: 4, 5, 6, 7, 8.
end note

note bottom of scm
  scm_actual_delivery_date is loaded and cleaned,
  but current classification reads actual_delivery_date
  from Internal DataFrame (CDD).
end note

@enduml
```
