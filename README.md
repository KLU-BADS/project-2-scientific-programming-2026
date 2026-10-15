# DeliveryStatusReport.jl

<!-- DO NOT EDIT BELOW -->
[![Tests](../../actions/workflows/tests.yml/badge.svg)](../../actions/workflows/tests.yml)
[![Documentation](../../actions/workflows/docs.yml/badge.svg)](../../actions/workflows/docs.yml)
<!-- DO NOT EDIT ABOVE -->


## Overview

<!-- DESCRIBE PROJECT PURPOSE BELOW -->
This tool automates the classification of supply chain order items by combining data from two sources, an internal order management database and an external shipment management system, to determine the delivery status of each item relative to its Requested Delivery Date (RDD).

#### Purpose:
In a supply chain, items can be at various stages of transit at any given time. This makes it difficult to identify at-risk deliveries without manual inspection. This program determines, without requiring manual input, for every tracked item, whether it is on track, at risk, or has already been delivered (on time or late).

#### Data Sources:
This tool is based upon four datasets. 
- Internal dataset (Internal_db.csv): provides the order item master data.
- Supply chain dataset (SCM_db.csv): provides shipment-level logistics data, specifically pickup city and the four key milestone dates:
  - Leg 1 Pickup Planned (date),
  - Leg 1 Pickup Actual (date),
  - Leg 1 Hub Arrival (date),
  - Leg n Delivery Actual (date). 
- Two lane transit matrices (lm_supplier_dc.csv and lm_logistics_dc.csv): lookup tables mapping origin cities to destination hubs with an estimated transit time in days.

#### How it works:
After loading and cleaning the data, each order item is matched to its corresponding shipment via an identifier. The program then inspects the shipment record to determine the last known milestone date, which defines one of three tracking stages.

If an actual delivery date is available, then the item has already arrived. It then compares that date against the RDD to classify it as ON_TIME or LATE (fulfilled deliveries).

If only a hub arrival date is present, then the item is on the final leg of transit. The program uses the lane transit matrix to estimate the remaining transit days from the hub to the destination, producing an estimated arrival date, which is then compared to the RDD to classify the item’s likelihood to arrive late.

If only a planned pickup date is available, then the item has not yet been collected. The program applies the full transit time from the lane matrix to estimate the expected arrival and classifies the item’s likelihood to arrive late.

#### Output:
The program writes the file `Final_Report.csv` (semicolon-separated). Each row is one order item, with the columns Project_ID, Shipment_ID, Items_Number, Material, Delivery_Status, ETA, Severity and Icon. It also prints a summary with the number of items per status and the number of urgent items.
  

<!-- DESCRIBE PROJECT PURPOSE ABOVE  -->

## Getting started

<!-- DO NOT EDIT BELOW -->
Clone the repository and start Julia in the project folder:

```bash
git clone https://github.com/KLU-BADS/project-2-scientific-programming-2026.git
cd project-2-scientific-programming-2026
julia --project=.
```
<!-- DO NOT EDIT ABOVE -->


<!-- DESCRIBE THE ESSENTIAL USAGE BELOW -->
### Setup

Julia 1.12 or newer is required. After cloning, the packages this project
depends on are not on your machine yet. Download and build them once.

Start Julia in the project folder, using the project's own environment:

```bash
julia --project=.
```

Then run the package manager command that installs everything listed in
`Project.toml`:

```julia
using Pkg
Pkg.instantiate()
```

### Run

Start Julia with `julia --project=.` and run:

```julia
using Project2
main()
```

`main()` reads the four CSV files in `data/`, classifies every order item,
prints a short summary and writes the report to `Final_Report.csv` in the
current folder. The file is separated by semicolons, so it opens correctly
in Excel.

<!-- DESCRIBE THE ESSENTIAL USAGE ABOVE -->

## Tests

<!-- DO NOT EDIT BELOW -->
Tests are run automatically on GitHub for every push to `main` and on every pull request.

> [!TIP]
> To run the tests locally, run
> ```bash
> julia --project=. -e 'using Pkg; Pkg.test()'
> ```
 
<!-- DO NOT EDIT ABOVE -->


## Documentation

<!-- DO NOT EDIT BELOW -->
The [online documentation](https://klu-bads.github.io/project-2-scientific-programming-2026/) is automatically built and published to GitHub Pages on every push to `main`.

> [!TIP]
> To build the documentation locally, run
> ```bash
> julia --project=docs docs/make.jl
> ```
> and open `docs/build/index.html` in a browser.
>
> If building the documentation fails, run the tests locally before. 


<!-- DO NOT EDIT ABOVE -->

## Contributing

<!-- DO NOT EDIT BELOW -->
See [CONTRIBUTING.md](CONTRIBUTING.md).
<!-- DO NOT EDIT ABOVE -->

## License

<!-- DO NOT EDIT BELOW -->
MIT. See [LICENSE](LICENSE).
<!-- DO NOT EDIT ABOVE -->
