# 🏢 PropFind: Hybrid Real Estate Intelligence & Analytics Platform

![MySQL](https://img.shields.io/badge/MySQL-Relational_DB-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-NoSQL_Document_DB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Python](https://img.shields.io/badge/Python-DB--API_%7C_Analytics-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=for-the-badge&logo=jupyter&logoColor=white)

## 📌 Project Overview

**PropFind** is a hybrid database and real estate analytics system designed to manage, query, and visualize housing market data across Indian cities. By combining the transactional integrity of a **normalized relational database (MySQL)** with the schema flexibility of a **document-oriented NoSQL database (MongoDB)**, PropFind demonstrates how modern data architectures handle both structured operational records and attribute-heavy feature catalogs.

---

## 🗂️ Dataset

* **Source:** [India Real Estate Intelligence Dataset (2025–2026)](https://www.kaggle.com/datasets/kuldeepjangra/india-real-estate-intelligence-dataset-20252026)
* **Domain Coverage:** Residential and commercial properties, historical property transactions, city and state socioeconomic indicators, developer profiles, nearby infrastructure (schools, shopping malls), and property amenities.

---

## 🏗️ Hybrid System Architecture

| Component | Technology | Role in PropFind |
| :--- | :--- | :--- |
| **Relational Store** | MySQL / MySQL Workbench | Stores normalized (3NF) core entities (`properties`, `property_transactions`, `cities`, `states`, `developers`, `property_types`, `schools`, `shopping_malls`) with strict Primary/Foreign Key constraints. |
| **Document Store** | MongoDB / MongoDB Compass | Stores flexible, tag-rich feature metadata (`amenities_master`) with dynamic attributes (`Category`, `Premium_Level`, `Indoor_Outdoor`, `Eco_Friendly`, `Family_Friendly`). |
| **Analytics & Integration** | Python (PEP 249 DB-API, PyMongo, Pandas, Matplotlib, Seaborn) | Connects to both databases via Jupyter Notebook to execute parameterized queries, manage transactions, and generate market visualizations. |

### Why a Hybrid Approach?
* **SQL (MySQL):** Ideal for financial transactions, multi-table analytical joins, and maintaining ACID compliance across structured entities.
* **NoSQL (MongoDB):** Real estate amenities continuously evolve with new descriptive tags and classifications. Storing amenities as JSON documents avoids rigid schema alterations (`ALTER TABLE`) and sparse columns while enabling fast tag-based filtering and aggregation.

---

## ✨ Key Features Implemented

### 1. Relational Database Design & Normalization (MySQL)
* **Entity-Relationship (ER) Modeling:** Designed a multi-table schema linking properties to geographical, developer, and infrastructure entities.
* **Normalization (Up to 3NF):** Eliminated transitive dependencies and update anomalies by separating repeating attributes into dedicated lookup tables (`cities`, `states`, `developers`, `property_types`).
* **Analytical SQL Queries:** Computed city-wise price per sq. ft., property-type valuations, yearly transaction volumes, and city-tier price vs. rental yield comparisons.

### 2. Python DB-API 2.0 Integration & Visualization
* **PEP 249 Compliance:** Implemented secure database connectivity using `mysql-connector-python` with cursors, parameterized queries (`%s`) to prevent SQL injection, and explicit transaction control (`commit()` / `rollback()`).
* **Exploratory Data Visualizations:**
  * Top 10 Cities by Average Price per Sq. Ft. (Bar Chart)
  * Average Price per Sq. Ft. by Property Type (Bar Chart)
  * Yearly Real Estate Transaction Volume (Line Chart)
  * Property Price Distribution Across City Tiers (Box Plot)
  * Property Price vs. Rental Rate per Sq. Ft. (Scatter Plot)

### 3. NoSQL Modeling & Aggregation (MongoDB)
* **CRUD Operations:** Executed document insertion (`insertOne` / `insertMany`), attribute filtering (`find`), field updates (`updateOne` with `$set`), and cleanup (`deleteOne` / `deleteMany`).
* **Indexing Strategy:** Created a unique index on `Amenity_ID` to prevent duplicate entries and a compound index on `{ Category: 1, Premium_Level: 1 }` to optimize multi-attribute queries.
* **Aggregation Pipeline:** Built a multi-stage pipeline (`$match` → `$group` → `$sort`) to analyze family-friendly amenities grouped by category and premium tier.

---

## 📁 Suggested Repository Structure

```text
PropFind-Real-Estate-Analytics/
│
├── sql/
│   ├── schema_ddl.sql              # Table creation, primary & foreign keys
│   └── analytical_queries.sql      # Price-per-sqft, tier, and trend queries
│
├── mongodb/
│   ├── amenities_sample.json       # Sample JSON documents for amenities_master
│   └── crud_and_aggregations.js    # CRUD, index creation, and aggregation pipeline
│
├── notebooks/
│   └── PropFind_Analytics.ipynb    # Python DB-API connection & Seaborn/Matplotlib plots
│
├── diagrams/
│   ├── er_diagram.png              # Exported MySQL Workbench EER diagram
│   └── compass_aggregation.png     # MongoDB Compass pipeline output screenshot
│
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
* **MySQL Server** & **MySQL Workbench**
* **MongoDB Community Server** & **MongoDB Compass**
* **Python 3.9+** with Jupyter Notebook

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/PropFind-Real-Estate-Analytics.git
   cd PropFind-Real-Estate-Analytics
   ```

2. **Set Up the MySQL Database**
   * Open **MySQL Workbench**, create a new database (e.g., `propfind_db`), and run the DDL scripts in `sql/schema_ddl.sql`.
   * Import the CSV files from the Kaggle dataset into their respective tables.

3. **Set Up the MongoDB Collection**
   * Open **MongoDB Compass** and connect to `mongodb://localhost:27017`.
   * Create a database named `propfind_db` and a collection named `amenities_master`.
   * Import `amenities_master.csv` (or `mongodb/amenities_sample.json`) into the collection, then run the indexes and aggregation pipeline in `mongodb/crud_and_aggregations.js`.

4. **Install Python Dependencies & Run the Notebook**
   ```bash
   pip install mysql-connector-python pymongo pandas matplotlib seaborn jupyter
   jupyter notebook notebooks/PropFind_Analytics.ipynb
   ```
   * Update the MySQL connection credentials (`host`, `user`, `password`, `database`) in the first cell and run all cells to reproduce the charts.

---

## 📊 Sample MongoDB Aggregation Pipeline

```javascript
db.amenities_master.aggregate([
  { $match: { Family_Friendly: "Yes" } },
  {
    $group: {
      _id: {
        Category: "$Category",
        Premium_Level: "$Premium_Level"
      },
      total_amenities: { $sum: 1 }
    }
  },
  { $sort: { total_amenities: -1 } }
])
```

---

## 📄 License & Acknowledgments
* Dataset provided by [Kuldeep Jangra on Kaggle](https://www.kaggle.com/datasets/kuldeepjangra/india-real-estate-intelligence-dataset-20252026).
* Developed as part of the **DBMS for Analytics** curriculum (*M.Sc. Data Science*).