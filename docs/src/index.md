# Delivery_Status_Report.jl

## **Overview**

This tool automates the classification of supply chain order items by combining data from two sources, an internal order management database and an external shipment management system, to determine the delivery status of each item relative to its Requested Delivery Date (RDD).

## **Purpose:**

In a supply chain, items can be at various stages of transit at any given time. This makes it difficult to identify at-risk deliveries without manual inspection. This program determines, without requiring manual input, for every tracked item, whether it is on track, at risk, or has already been delivered (on time or late).

## **Data Sources:**

This tool is based upon three datasets.

* **Internal dataset (`internal_bd.csv`):** provides the order item master data.
* **Supply chain dataset (`SCM_db.csv`):** provides shipment-level logistics data, specifically pickup city and the three key milestone dates:

  * Leg 1 Pickup Planned (date),
  * Leg 1 Hub Arrival (date),
  * Leg n Delivery Actual (date).
* **Lane transit matrix:** provides a lookup table mapping origin cities to destination hubs with an estimated transit time in days.

## **How it works:**

After loading and cleaning the data, each order item is matched to its corresponding shipment via an identifier. The program then inspects the shipment record to determine the last known milestone date, which defines one of three tracking stages.

### **1. Actual Delivery Date Available**

If an actual delivery date is available, then the item has already arrived. It then compares that date against the RDD to classify it as `ON_TIME` or `LATE` (fulfilled deliveries).

### **2. Hub Arrival Date Available**

If only a hub arrival date is present, then the item is on the final leg of transit. The program uses the lane transit matrix to estimate the remaining transit days from the hub to the destination, producing an estimated arrival date, which is then compared to the RDD to classify the item’s likelihood to arrive late.

### **3. Planned Pickup Date Available**

If only a planned pickup date is available, then the item has not yet been collected. The program applies the full transit time from the lane matrix to estimate the expected arrival and classifies the item’s likelihood to arrive late.

## **Output**

The program produces an array with the project identification number, shipment identification number, and item number, in which every item has an assigned delivery status, an estimated date of arrival, and the tracking stage based on the classification. It also provides a summary of all active shipments, their delivery states, as well as the amount of shipments requiring immediate attention.


---

Replace the content of `docs/src/index.md` with a description of your project. Change `docs/make.jl` to add new sections to your documentation.

Build this documentation locally with `julia --project=docs docs/make.jl`, and
open `docs/build/index.html` in a browser.

([Google Sheet Link](https://docs.google.com/spreadsheets/d/1i4w_m8qUZK3gLhk4Sh34GVwpmJUhRAN8yYhj_86Vn6g/edit?usp=sharing))
