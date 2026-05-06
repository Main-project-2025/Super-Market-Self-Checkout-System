# Super-Market Self-Checkout System Database Schema

Below is the Entity-Relationship (ER) diagram for the SQLite database based on the initialization script (`backend/database/init.js`).

```mermaid
erDiagram
    users {
        INTEGER id PK "AUTOINCREMENT"
        TEXT email "UNIQUE NOT NULL"
        TEXT password "NOT NULL"
        TEXT name "NOT NULL"
        TEXT role "DEFAULT 'customer'"
        DATETIME created_at "DEFAULT CURRENT_TIMESTAMP"
        DATETIME updated_at "DEFAULT CURRENT_TIMESTAMP"
    }

    products {
        TEXT id PK
        TEXT name "NOT NULL"
        REAL price "NOT NULL"
        TEXT barcode "UNIQUE NOT NULL"
        TEXT description
        TEXT category
        INTEGER stock_quantity "DEFAULT 0"
        TEXT image_url
        BOOLEAN is_active "DEFAULT 1"
        DATETIME created_at "DEFAULT CURRENT_TIMESTAMP"
        DATETIME updated_at "DEFAULT CURRENT_TIMESTAMP"
    }

    transactions {
        TEXT id PK
        INTEGER user_id FK "NOT NULL"
        REAL total_amount "NOT NULL"
        TEXT status "DEFAULT 'pending'"
        TEXT payment_method
        TEXT qr_code_data
        DATETIME created_at "DEFAULT CURRENT_TIMESTAMP"
        DATETIME updated_at "DEFAULT CURRENT_TIMESTAMP"
    }

    transaction_items {
        INTEGER id PK "AUTOINCREMENT"
        TEXT transaction_id FK "NOT NULL"
        TEXT product_id FK "NOT NULL"
        INTEGER quantity "NOT NULL"
        REAL unit_price "NOT NULL"
        REAL total_price "NOT NULL"
        DATETIME created_at "DEFAULT CURRENT_TIMESTAMP"
    }

    users ||--o{ transactions : "places"
    transactions ||--|{ transaction_items : "contains"
    products ||--o{ transaction_items : "included in"
```

## Table Descriptions

- **`users`**: Stores user account information ranging from regular customers to staff and admins.
- **`products`**: Maintains an inventory of all items available for scanning and checkout. Each product has a unique `barcode`.
- **`transactions`**: Records all checkout transaction occurrences associated with a specific user. The final state tracking is based on the `status` string.
- **`transaction_items`**: Junction mapping individual products that were scanned into a specific transaction, keeping track of individual quantities and prices at the time of purchase.
