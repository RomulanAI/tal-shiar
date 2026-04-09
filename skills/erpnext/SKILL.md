---
name: erpnext
description: ERPNext / Frappe REST API — query, create, update, and analyze business data in the company ERPNext instance (Romulan AI Pvt. Ltd.). Triggers when user asks about: invoices, customers, suppliers, items, sales orders, purchase orders, stock, inventory, accounting, ledger entries, trial balance, profit & loss, balance sheet, GST, TDS, payroll, employees, manufacturing, BOM, work orders, warehouses, payments, reports, financial analysis, or any ERP/business operations. Also triggers for questions about the ERPNext API itself, building integrations, or automating business processes.
---

# ERPNext API Skill

Complete reference for interacting with the ERPNext instance at Romulan AI Pvt. Ltd. via the Frappe REST API.

---

## Our Instance

| Detail | Value |
|--------|-------|
| **Base URL** | `http://host.containers.internal:43625` (from inside this container) |
| **Frappe version** | 15.77.0 |
| **ERPNext version** | 15.76.0 |
| **Company** | Romulan AI Pvt. Ltd. (abbr: RAIPL) |
| **Country / Currency** | India / INR |
| **Fiscal Year** | 2025-2026 (April to March) |
| **GST Category** | Registered Regular |
| **GSTIN** | 27AAMCR7846J1ZM |
| **PAN** | AAMCR7846J |
| **Default Bank** | HDFC Bank Current Account - RAIPL |
| **Installed Apps** | ERPNext, Frappe HR (HRMS), Payments, Print Designer, GST India, Income Tax India, Webshop, Audit Trail |

### Authentication

Every request must include the auth header:
```
Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET
```

Both environment variables are set inside this container. Use them directly:
```bash
curl -s -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  "http://host.containers.internal:43625/api/resource/Company"
```

### Key Accounts

| Account | Purpose |
|---------|---------|
| HDFC Bank Current Account - RAIPL | Primary bank |
| Cash - RAIPL | Cash in hand |
| Debtors - RAIPL | Accounts receivable |
| Creditors - RAIPL | Accounts payable |
| Sales - RAIPL | Default income |
| Service - RAIPL | Service income |
| Cost of Goods Sold - RAIPL | Direct expense |
| Salary - RAIPL | Staff costs |
| Stock In Hand - RAIPL | Inventory asset |
| Payroll Payable - RAIPL | Payroll liability |
| Main - RAIPL | Default cost center |

### Warehouses

| Warehouse | Purpose |
|-----------|---------|
| Stores - RAIPL | Raw materials / incoming |
| Work In Progress - RAIPL | Manufacturing WIP |
| Finished Goods - RAIPL | Completed products |
| Goods In Transit - RAIPL | Shipments in transit |

### Shareholders / Loans

- Share Capital: Mr. Prasanna Bhogale, Mr. Kaushal Bheda
- Unsecured Loans from: Mr. Prasanna Bhogale, Mr. Kaushal Bheda

---

## 1. Frappe REST API Fundamentals

### Base Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/resource/{DocType}` | List documents |
| GET | `/api/resource/{DocType}/{name}` | Get single document |
| POST | `/api/resource/{DocType}` | Create document |
| PUT | `/api/resource/{DocType}/{name}` | Update document |
| DELETE | `/api/resource/{DocType}/{name}` | Delete document |
| GET/POST | `/api/method/{dotted.path}` | Call whitelisted method |

**DocType names use spaces, not underscores.** URL-encode them: `Sales%20Order`, `GL%20Entry`, `Purchase%20Invoice`.

### Listing Documents (GET /api/resource/{DocType})

#### Field Selection
```bash
# Select specific fields
curl "$BASE/api/resource/Customer?fields=[\"name\",\"customer_name\",\"customer_group\",\"territory\",\"outstanding_amount\"]"

# All fields
curl "$BASE/api/resource/Customer?fields=[\"*\"]"
```

#### Filters

Filters are JSON arrays of conditions: `[fieldname, operator, value]`

```bash
# Simple equality
?filters=[["status","=","Open"]]

# Multiple conditions (AND)
?filters=[["status","=","Submitted"],["grand_total",">",10000]]

# Available operators:
#   =, !=, >, <, >=, <=
#   like, not like          (use % as wildcard: "like", "%partial%")
#   in, not in              (value is a list: ["Draft","Submitted"])
#   between                 (value is [start, end])
#   is, is not              ("set" or "not set" for null checks)
```

**Examples:**
```bash
# Sales orders this month
?filters=[["transaction_date","between",["2026-03-01","2026-03-31"]]]

# Unpaid invoices above 5000
?filters=[["outstanding_amount",">",5000],["docstatus","=",1]]

# Items in a specific group
?filters=[["item_group","=","Raw Material"]]

# Name search with wildcard
?filters=[["customer_name","like","%Romulan%"]]

# Null check
?filters=[["phone","is","not set"]]
```

#### OR Filters

Use `or_filters` for OR conditions (these are OR'd with each other, then AND'd with `filters`):
```bash
?filters=[["docstatus","=",1]]&or_filters=[["status","=","Overdue"],["status","=","Unpaid"]]
```

#### Pagination

```bash
# First page (default: 20 results)
?limit_page_length=20&limit_start=0

# Second page
?limit_page_length=20&limit_start=20

# ALL results (use carefully on large tables)
?limit_page_length=0
```

#### Ordering

```bash
# Sort by date descending
?order_by=transaction_date desc

# Multiple sort keys
?order_by=status asc, grand_total desc

# Default: modified desc
```

#### Grouping

```bash
# Group by with aggregation
?fields=["customer","count(name) as count","sum(grand_total) as total"]&group_by=customer
```

#### Combining Everything

```bash
curl -s -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  "http://host.containers.internal:43625/api/resource/Sales%20Invoice?\
fields=[\"name\",\"customer\",\"grand_total\",\"status\",\"posting_date\"]&\
filters=[[\"posting_date\",\"between\",[\"2025-04-01\",\"2026-03-31\"]],[\"docstatus\",\"=\",1]]&\
order_by=posting_date desc&\
limit_page_length=50&\
limit_start=0"
```

### Getting a Single Document

```bash
# Full document with all fields and child tables
curl "$BASE/api/resource/Sales%20Order/SO-00042"

# Response includes:
# - All fields of the parent document
# - All child table rows (e.g., "items", "taxes")
# - Workflow state, docstatus, owner, timestamps
```

### Document Status (docstatus)

| Value | Meaning | Description |
|-------|---------|-------------|
| 0 | Draft | Not yet submitted |
| 1 | Submitted | Finalized, creates ledger entries |
| 2 | Cancelled | Reversed / voided |

**Always filter by `docstatus` when you need only valid documents:**
```bash
?filters=[["docstatus","=",1]]
```

### Creating Documents

```bash
# Create a Customer
curl -X POST -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  "$BASE/api/resource/Customer" \
  -d '{
    "customer_name": "Acme Corp",
    "customer_type": "Company",
    "customer_group": "Commercial",
    "territory": "India"
  }'

# Create with child table (e.g., Sales Order with items)
curl -X POST -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  "$BASE/api/resource/Sales%20Order" \
  -d '{
    "customer": "Acme Corp",
    "delivery_date": "2026-04-15",
    "items": [
      {
        "item_code": "ITEM-001",
        "qty": 10,
        "rate": 500
      }
    ]
  }'
```

### Updating Documents

```bash
# Update specific fields (PATCH semantics via PUT)
curl -X PUT -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  "$BASE/api/resource/Customer/Acme%20Corp" \
  -d '{
    "territory": "Maharashtra"
  }'
```

### Deleting Documents

```bash
curl -X DELETE -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  "$BASE/api/resource/Customer/Acme%20Corp"
```

**Note:** Submitted documents (docstatus=1) cannot be deleted directly. They must be cancelled first (amend -> cancel), then deleted.

### Submitting and Cancelling

```bash
# Submit a draft document (changes docstatus from 0 to 1)
curl -X PUT -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  "$BASE/api/resource/Sales%20Invoice/SINV-00001" \
  -d '{"docstatus": 1}'

# Cancel a submitted document (changes docstatus from 1 to 2)
curl -X PUT -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  "$BASE/api/resource/Sales%20Invoice/SINV-00001" \
  -d '{"docstatus": 2}'
```

---

## 2. Whitelisted Methods (frappe.client)

These are server-side methods callable via `/api/method/`.

### frappe.client.get_list
```bash
# More flexible than /api/resource -- supports server-side processing
curl -X POST "$BASE/api/method/frappe.client.get_list" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doctype=Sales Invoice&fields=["name","customer","grand_total"]&filters=[["docstatus","=",1]]&order_by=posting_date desc&limit_page_length=10'
```

### frappe.client.get_count
```bash
# Count documents matching filters
curl -X POST "$BASE/api/method/frappe.client.get_count" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doctype=Sales Invoice&filters=[["docstatus","=",1]]'
# Returns: {"message": 42}
```

### frappe.client.get
```bash
# Get a single document (same as /api/resource/{doctype}/{name})
curl -X POST "$BASE/api/method/frappe.client.get" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doctype=Company&name=Romulan AI Pvt. Ltd.'
```

### frappe.client.get_value
```bash
# Get specific field(s) from a document
curl -X POST "$BASE/api/method/frappe.client.get_value" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doctype=Company&fieldname=default_currency&filters={"name":"Romulan AI Pvt. Ltd."}'
```

### frappe.client.insert
```bash
# Create a document
curl -X POST "$BASE/api/method/frappe.client.insert" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"doc": {"doctype": "ToDo", "description": "Follow up on invoice"}}'
```

### frappe.client.save
```bash
# Save (update) a document
curl -X POST "$BASE/api/method/frappe.client.save" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"doc": {"doctype": "ToDo", "name": "TODO-00001", "status": "Closed"}}'
```

### frappe.client.delete
```bash
curl -X POST "$BASE/api/method/frappe.client.delete" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doctype=ToDo&name=TODO-00001'
```

### frappe.client.rename_doc
```bash
curl -X POST "$BASE/api/method/frappe.client.rename_doc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doctype=Item&old=OLD-NAME&new=NEW-NAME'
```

---

## 3. DocType Metadata

### Get field definitions for any DocType
```bash
# Full schema including field types, options, and child tables
curl "$BASE/api/resource/DocType/Sales%20Invoice" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# This returns:
# - fields[]: name, fieldtype, label, options (for Link/Select), reqd, etc.
# - Child table references (fieldtype: "Table", options: "Sales Invoice Item")
```

### Common field types
| Fieldtype | Description |
|-----------|-------------|
| Data | Short text |
| Text / Small Text | Long text |
| Int / Float / Currency | Numbers |
| Date / Datetime | Dates |
| Link | Foreign key to another DocType |
| Table | Child table (one-to-many) |
| Select | Dropdown (options are newline-separated) |
| Check | Boolean (0/1) |
| Attach | File attachment |

### List all DocTypes in a module
```bash
curl "$BASE/api/resource/DocType?filters=[[\"module\",\"=\",\"Accounts\"]]&fields=[\"name\"]&limit_page_length=0" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
```

---

## 4. Reports API

ERPNext has 100+ built-in reports. Call any of them programmatically.

### Running a Report
```bash
curl -X POST "$BASE/api/method/frappe.desk.query_report.run" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'report_name=General Ledger&filters={"company":"Romulan AI Pvt. Ltd.","from_date":"2025-04-01","to_date":"2026-03-31"}'
```

Response structure:
```json
{
  "message": {
    "columns": [...],
    "result": [...],
    "chart": {...},
    "report_summary": [...]
  }
}
```

### Key Financial Reports

#### General Ledger
```bash
-d 'report_name=General Ledger&filters={"company":"Romulan AI Pvt. Ltd.","from_date":"2025-04-01","to_date":"2026-03-31","account":"HDFC Bank Current Account - RAIPL"}'
```

#### Trial Balance
```bash
-d 'report_name=Trial Balance&filters={"company":"Romulan AI Pvt. Ltd.","fiscal_year":"2025-2026"}'
```

#### Profit and Loss Statement
```bash
-d 'report_name=Profit and Loss Statement&filters={"company":"Romulan AI Pvt. Ltd.","fiscal_year":"2025-2026","periodicity":"Monthly"}'
```

#### Balance Sheet
```bash
-d 'report_name=Balance Sheet&filters={"company":"Romulan AI Pvt. Ltd.","fiscal_year":"2025-2026","periodicity":"Yearly"}'
```

#### Cash Flow
```bash
-d 'report_name=Cash Flow&filters={"company":"Romulan AI Pvt. Ltd.","fiscal_year":"2025-2026","periodicity":"Monthly"}'
```

#### Gross Profit
```bash
-d 'report_name=Gross Profit&filters={"company":"Romulan AI Pvt. Ltd.","from_date":"2025-04-01","to_date":"2026-03-31"}'
```

### Sales Reports

| Report Name | Key Filters |
|-------------|-------------|
| Sales Analytics | company, from_date, to_date, tree_type (Customer/Item Group/etc.) |
| Sales Register | company, from_date, to_date, customer |
| Item-wise Sales Register | company, from_date, to_date |
| Item-wise Sales History | company, from_date, to_date, item_group |
| Sales Order Analysis | company, from_date, to_date, status |
| Sales Person-wise Transaction Summary | company, fiscal_year |
| Customer Ledger Summary | company, from_date, to_date |
| Territory-wise Sales | company, fiscal_year |
| Sales Payment Summary | company, from_date, to_date |

### Purchase Reports

| Report Name | Key Filters |
|-------------|-------------|
| Purchase Analytics | company, from_date, to_date |
| Purchase Register | company, from_date, to_date |
| Item-wise Purchase Register | company, from_date, to_date |
| Item-wise Purchase History | company, from_date, to_date |
| Purchase Order Analysis | company, from_date, to_date |
| Supplier Ledger Summary | company, from_date, to_date |

### Stock Reports

| Report Name | Key Filters |
|-------------|-------------|
| Stock Balance | company, from_date, to_date, warehouse |
| Stock Ledger | company, from_date, to_date, item_code, warehouse |
| Stock Analytics | company, from_date, to_date |
| Stock Ageing | company, to_date, warehouse |
| Stock Projected Qty | company, warehouse |
| Warehouse Wise Stock Balance | company |

### Accounting Reports

| Report Name | Key Filters |
|-------------|-------------|
| Accounts Receivable | company, report_date |
| Accounts Payable | company, report_date |
| Payment Ledger | company, from_date, to_date |
| Voucher-wise Balance | company, fiscal_year |
| Profitability Analysis | company, fiscal_year, based_on (Cost Center/Project) |

### GST Reports (India-specific)

| Report Name | Key Filters |
|-------------|-------------|
| GSTR-1 | company, company_gstin, from_date, to_date |
| GSTR-3B Details | company, company_gstin, year, month |
| GST Balance | company, company_gstin, from_date, to_date |
| GST Sales Register | company, from_date, to_date |
| GST Purchase Register | company, from_date, to_date |
| GST Itemised Sales Register | company, from_date, to_date |
| GST Itemised Purchase Register | company, from_date, to_date |
| TDS Computation Summary | company, from_date, to_date |

### HR / Payroll Reports

| Report Name | Key Filters |
|-------------|-------------|
| Employee Information | company |
| Employee Leave Balance | company, from_date, to_date |
| Employee Leave Balance Summary | company, from_date, to_date |
| Income Tax Computation | company, payroll_period |
| Professional Tax Deductions | company, from_date, to_date |

---

## 5. Document Workflows & Business Processes

### Sales Cycle

```
Lead -> Opportunity -> Quotation -> Sales Order -> Delivery Note -> Sales Invoice -> Payment Entry
```

| Step | DocType | Creates |
|------|---------|---------|
| Quote | Quotation | -- |
| Order confirmed | Sales Order | Reserved stock |
| Ship goods | Delivery Note | Stock ledger entries |
| Bill customer | Sales Invoice | GL entries (Debtors <-> Income) |
| Receive payment | Payment Entry | GL entries (Bank <-> Debtors) |

**Creating from a previous step:**
```bash
# Create Sales Invoice from Sales Order
curl -X POST "$BASE/api/method/erpnext.selling.doctype.sales_order.sales_order.make_sales_invoice" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'source_name=SO-00001'
# Returns a draft Sales Invoice -- save it with frappe.client.insert
```

### Purchase Cycle

```
Material Request -> Supplier Quotation -> Purchase Order -> Purchase Receipt -> Purchase Invoice -> Payment Entry
```

| Step | DocType | Creates |
|------|---------|---------|
| Request material | Material Request | -- |
| Get quote | Supplier Quotation | -- |
| Place order | Purchase Order | -- |
| Receive goods | Purchase Receipt | Stock ledger entries |
| Record bill | Purchase Invoice | GL entries (Expense <-> Creditors) |
| Make payment | Payment Entry | GL entries (Creditors <-> Bank) |

### Manufacturing Cycle

```
BOM -> Work Order -> Stock Entry (Material Transfer) -> Stock Entry (Manufacture) -> Quality Inspection
```

| Step | DocType | Purpose |
|------|---------|---------|
| Define recipe | BOM (Bill of Materials) | Lists raw materials + operations |
| Plan production | Work Order | Specifies qty to produce |
| Issue materials | Stock Entry (Material Transfer for Manufacture) | Moves raw materials to WIP |
| Complete production | Stock Entry (Manufacture) | Consumes WIP, creates Finished Goods |

### Payment & Reconciliation

```bash
# Create a Payment Entry
curl -X POST "$BASE/api/resource/Payment%20Entry" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_type": "Receive",
    "party_type": "Customer",
    "party": "Acme Corp",
    "paid_amount": 50000,
    "received_amount": 50000,
    "paid_from": "Debtors - RAIPL",
    "paid_to": "HDFC Bank Current Account - RAIPL",
    "reference_no": "NEFT-12345",
    "reference_date": "2026-03-26",
    "references": [
      {
        "reference_doctype": "Sales Invoice",
        "reference_name": "SINV-00001",
        "allocated_amount": 50000
      }
    ]
  }'
```

---

## 6. Analytics Patterns

### Aggregation Queries

```bash
# Total sales by customer
curl "$BASE/api/resource/Sales%20Invoice?fields=[\"customer\",\"sum(grand_total) as total\"]&filters=[[\"docstatus\",\"=\",1]]&group_by=customer&order_by=total desc&limit_page_length=10" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Monthly revenue
curl "$BASE/api/resource/Sales%20Invoice?fields=[\"month(posting_date) as month\",\"sum(grand_total) as revenue\"]&filters=[[\"docstatus\",\"=\",1],[\"fiscal_year\",\"=\",\"2025-2026\"]]&group_by=month&order_by=month asc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Item-wise quantity sold
curl "$BASE/api/resource/Sales%20Invoice%20Item?fields=[\"item_code\",\"item_name\",\"sum(qty) as total_qty\",\"sum(amount) as total_amount\"]&filters=[[\"docstatus\",\"=\",1]]&group_by=item_code&order_by=total_amount desc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
```

### Date-Range Queries

```bash
# This fiscal year
?filters=[["posting_date","between",["2025-04-01","2026-03-31"]]]

# Last 30 days
?filters=[["posting_date",">=","2026-02-24"]]

# Specific month
?filters=[["posting_date","between",["2026-03-01","2026-03-31"]]]
```

### Financial Analysis via GL Entries

```bash
# All GL entries for an account (e.g., bank reconciliation)
curl "$BASE/api/resource/GL%20Entry?fields=[\"posting_date\",\"account\",\"debit\",\"credit\",\"against\",\"voucher_type\",\"voucher_no\",\"remarks\"]&filters=[[\"account\",\"=\",\"HDFC Bank Current Account - RAIPL\"],[\"is_cancelled\",\"=\",0]]&order_by=posting_date desc&limit_page_length=0" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Account balance calculation
# Sum(debit) - Sum(credit) for asset/expense accounts
# Sum(credit) - Sum(debit) for liability/income/equity accounts
curl "$BASE/api/resource/GL%20Entry?fields=[\"sum(debit) as total_debit\",\"sum(credit) as total_credit\"]&filters=[[\"account\",\"=\",\"HDFC Bank Current Account - RAIPL\"],[\"is_cancelled\",\"=\",0]]" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
```

### Outstanding Amounts

```bash
# Customers with outstanding balances
curl "$BASE/api/resource/Sales%20Invoice?fields=[\"customer\",\"sum(outstanding_amount) as outstanding\"]&filters=[[\"docstatus\",\"=\",1],[\"outstanding_amount\",\">\",0]]&group_by=customer&order_by=outstanding desc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Overdue invoices
curl "$BASE/api/resource/Sales%20Invoice?fields=[\"name\",\"customer\",\"grand_total\",\"outstanding_amount\",\"due_date\"]&filters=[[\"docstatus\",\"=\",1],[\"outstanding_amount\",\">\",0],[\"due_date\",\"<\",\"2026-03-26\"]]&order_by=due_date asc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
```

### Stock Analytics

```bash
# Current stock levels by warehouse
curl "$BASE/api/resource/Bin?fields=[\"item_code\",\"warehouse\",\"actual_qty\",\"valuation_rate\",\"stock_value\"]&filters=[[\"actual_qty\",\">\",0]]&order_by=stock_value desc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Stock movement for an item
curl "$BASE/api/resource/Stock%20Ledger%20Entry?fields=[\"posting_date\",\"warehouse\",\"actual_qty\",\"qty_after_transaction\",\"valuation_rate\",\"voucher_type\",\"voucher_no\"]&filters=[[\"item_code\",\"=\",\"ITEM-001\"]]&order_by=posting_date desc" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
```

---

## 7. Linked Documents & Child Tables

### Accessing Child Table Rows

When you GET a parent document, child tables come embedded:
```json
{
  "name": "SO-00001",
  "customer": "Acme Corp",
  "items": [
    {"item_code": "ITEM-001", "qty": 10, "rate": 500, "amount": 5000},
    {"item_code": "ITEM-002", "qty": 5, "rate": 1000, "amount": 5000}
  ],
  "taxes": [
    {"charge_type": "On Net Total", "account_head": "Output Tax IGST - RAIPL", "rate": 18}
  ]
}
```

### Querying Child Tables Directly

Child tables are DocTypes too -- query them like any other:
```bash
# All line items across all submitted Sales Orders
curl "$BASE/api/resource/Sales%20Order%20Item?fields=[\"parent\",\"item_code\",\"qty\",\"rate\",\"amount\"]&filters=[[\"docstatus\",\"=\",1]]&limit_page_length=0" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Filter by parent
?filters=[["parent","=","SO-00001"]]
```

### Finding Linked Documents

```bash
# Find all Sales Invoices linked to a Sales Order
curl "$BASE/api/resource/Sales%20Invoice%20Item?fields=[\"parent\"]&filters=[[\"sales_order\",\"=\",\"SO-00001\"],[\"docstatus\",\"=\",1]]" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"

# Find all Delivery Notes for a customer
curl "$BASE/api/resource/Delivery%20Note?fields=[\"name\",\"posting_date\",\"grand_total\"]&filters=[[\"customer\",\"=\",\"Acme Corp\"],[\"docstatus\",\"=\",1]]" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
```

---

## 8. File Upload

```bash
# Upload a file
curl -X POST "$BASE/api/method/upload_file" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -F "file=@/path/to/document.pdf" \
  -F "is_private=1" \
  -F "doctype=Sales Invoice" \
  -F "docname=SINV-00001"

# Response includes file_url for the uploaded file
```

---

## 9. Bulk Operations

### Insert Multiple Documents
```bash
curl -X POST "$BASE/api/method/frappe.client.insert_many" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"docs": [
    {"doctype": "Customer", "customer_name": "Client A", "customer_type": "Company"},
    {"doctype": "Customer", "customer_name": "Client B", "customer_type": "Company"}
  ]}'
```

### Bulk Update via Method
```bash
# Cancel multiple documents
for name in SINV-00001 SINV-00002 SINV-00003; do
  curl -X POST "$BASE/api/method/frappe.client.cancel" \
    -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
    -d "doctype=Sales Invoice&name=$name"
done
```

---

## 10. Run Doc Method

Call methods defined on a specific document:

```bash
# Example: Get the payment entry for an invoice
curl -X POST "$BASE/api/method/frappe.client.run_doc_method" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'dt=Sales Invoice&dn=SINV-00001&method=make_payment_entry'
```

Common doc methods:
- Sales Order: `make_sales_invoice`, `make_delivery_note`, `make_purchase_order`
- Purchase Order: `make_purchase_receipt`, `make_purchase_invoice`
- Sales Invoice: `make_payment_entry`

---

## 11. Error Handling

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 403 | Permission denied (check user roles) |
| 404 | Document/DocType not found |
| 409 | Conflict (e.g., duplicate name) |
| 417 | Validation error (e.g., missing required field) |
| 500 | Server error |

### Error Response Format
```json
{
  "exc_type": "ValidationError",
  "exception": "frappe.exceptions.ValidationError: Customer Name is required",
  "_server_messages": "[\"Customer Name is required\"]"
}
```

### Common Pitfalls

1. **URL-encode DocType names**: `Sales Order` -> `Sales%20Order`
2. **Always include `docstatus` filter** for transactional docs -- otherwise you get drafts + cancelled mixed in
3. **Child table names differ from parent**: `Sales Invoice Item` (not `Sales Invoice Items`)
4. **`limit_page_length` defaults to 20** -- use `0` for all results, but be careful on large tables
5. **Dates are `YYYY-MM-DD` format** -- always
6. **Currency fields return floats** -- watch for rounding (compare to 2 decimal places)
7. **Link fields store the `name`** (ID), not the display label
8. **Submitted docs are immutable** -- to change, amend (creates new version) or cancel

---

## 12. Useful Utility Methods

```bash
# Ping (health check)
curl "$BASE/api/method/frappe.ping"

# Get logged-in user info
curl "$BASE/api/method/frappe.auth.get_logged_user"

# Get system settings
curl "$BASE/api/resource/System%20Settings"

# Get version info
curl "$BASE/api/method/frappe.utils.change_log.get_versions"

# Search link field (autocomplete)
curl "$BASE/api/method/frappe.desk.search.search_link?doctype=Customer&txt=rom&page_length=5"

# Get print format (PDF)
curl "$BASE/api/method/frappe.utils.print_format.download_pdf?doctype=Sales%20Invoice&name=SINV-00001&format=Standard" -o invoice.pdf
```

---

## 13. Workflow & Approval

```bash
# Apply workflow action
curl -X POST "$BASE/api/method/frappe.model.workflow.apply_workflow" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doc={"doctype":"Leave Application","name":"HR-LAP-00001"}&action=Approve'

# Get workflow transitions available for a document
curl "$BASE/api/method/frappe.model.workflow.get_transitions" \
  -H "Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET" \
  -d 'doc={"doctype":"Leave Application","name":"HR-LAP-00001"}'
```

---

## 14. Practical Recipes

### Recipe: Quick Financial Health Check
```bash
AUTH="Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
BASE="http://host.containers.internal:43625"

# 1. Bank balance
curl -s -H "$AUTH" "$BASE/api/resource/GL%20Entry?fields=[\"sum(debit)-sum(credit) as balance\"]&filters=[[\"account\",\"=\",\"HDFC Bank Current Account - RAIPL\"],[\"is_cancelled\",\"=\",0]]"

# 2. Total receivables
curl -s -H "$AUTH" "$BASE/api/resource/Sales%20Invoice?fields=[\"sum(outstanding_amount) as receivables\"]&filters=[[\"docstatus\",\"=\",1],[\"outstanding_amount\",\">\",0]]"

# 3. Total payables
curl -s -H "$AUTH" "$BASE/api/resource/Purchase%20Invoice?fields=[\"sum(outstanding_amount) as payables\"]&filters=[[\"docstatus\",\"=\",1],[\"outstanding_amount\",\">\",0]]"

# 4. Revenue this FY
curl -s -H "$AUTH" "$BASE/api/resource/Sales%20Invoice?fields=[\"sum(grand_total) as revenue\"]&filters=[[\"docstatus\",\"=\",1],[\"posting_date\",\"between\",[\"2025-04-01\",\"2026-03-31\"]]]"

# 5. P&L report
curl -s -X POST -H "$AUTH" "$BASE/api/method/frappe.desk.query_report.run" \
  -d 'report_name=Profit and Loss Statement&filters={"company":"Romulan AI Pvt. Ltd.","fiscal_year":"2025-2026","periodicity":"Yearly"}'
```

### Recipe: Customer 360 View
```bash
CUSTOMER="Acme Corp"
AUTH="Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
BASE="http://host.containers.internal:43625"

# Profile
curl -s -H "$AUTH" "$BASE/api/resource/Customer/$CUSTOMER"

# Orders
curl -s -H "$AUTH" "$BASE/api/resource/Sales%20Order?filters=[[\"customer\",\"=\",\"$CUSTOMER\"],[\"docstatus\",\"=\",1]]&fields=[\"name\",\"transaction_date\",\"grand_total\",\"status\"]&order_by=transaction_date desc"

# Invoices
curl -s -H "$AUTH" "$BASE/api/resource/Sales%20Invoice?filters=[[\"customer\",\"=\",\"$CUSTOMER\"],[\"docstatus\",\"=\",1]]&fields=[\"name\",\"posting_date\",\"grand_total\",\"outstanding_amount\",\"status\"]&order_by=posting_date desc"

# Payments
curl -s -H "$AUTH" "$BASE/api/resource/Payment%20Entry?filters=[[\"party\",\"=\",\"$CUSTOMER\"],[\"docstatus\",\"=\",1]]&fields=[\"name\",\"posting_date\",\"paid_amount\",\"reference_no\"]&order_by=posting_date desc"

# Lifetime value
curl -s -H "$AUTH" "$BASE/api/resource/Sales%20Invoice?fields=[\"sum(grand_total) as lifetime_value\",\"count(name) as invoice_count\"]&filters=[[\"customer\",\"=\",\"$CUSTOMER\"],[\"docstatus\",\"=\",1]]"
```

### Recipe: Inventory Status
```bash
AUTH="Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
BASE="http://host.containers.internal:43625"

# Current stock by item and warehouse
curl -s -H "$AUTH" "$BASE/api/resource/Bin?fields=[\"item_code\",\"warehouse\",\"actual_qty\",\"planned_qty\",\"reserved_qty\",\"ordered_qty\",\"projected_qty\",\"stock_value\"]&filters=[[\"actual_qty\",\"!=\",0]]&order_by=item_code asc"

# Low stock items (below reorder level)
curl -s -H "$AUTH" "$BASE/api/resource/Bin?fields=[\"item_code\",\"warehouse\",\"actual_qty\",\"projected_qty\"]&filters=[[\"projected_qty\",\"<\",0]]"

# Stock valuation summary
curl -s -X POST -H "$AUTH" "$BASE/api/method/frappe.desk.query_report.run" \
  -d 'report_name=Stock Balance&filters={"company":"Romulan AI Pvt. Ltd.","to_date":"2026-03-26"}'
```

### Recipe: GST Filing Prep
```bash
AUTH="Authorization: token $ERPNEXT_API_KEY:$ERPNEXT_API_SECRET"
BASE="http://host.containers.internal:43625"

# GSTR-1 (outward supplies)
curl -s -X POST -H "$AUTH" "$BASE/api/method/frappe.desk.query_report.run" \
  -d 'report_name=GSTR-1&filters={"company":"Romulan AI Pvt. Ltd.","company_gstin":"27AAMCR7846J1ZM","from_date":"2026-03-01","to_date":"2026-03-31"}'

# GSTR-3B
curl -s -X POST -H "$AUTH" "$BASE/api/method/frappe.desk.query_report.run" \
  -d 'report_name=GSTR-3B Details&filters={"company":"Romulan AI Pvt. Ltd.","company_gstin":"27AAMCR7846J1ZM","year":"2026","month":"March"}'

# GST balance check
curl -s -X POST -H "$AUTH" "$BASE/api/method/frappe.desk.query_report.run" \
  -d 'report_name=GST Balance&filters={"company":"Romulan AI Pvt. Ltd.","company_gstin":"27AAMCR7846J1ZM","from_date":"2025-04-01","to_date":"2026-03-31"}'
```

---

## 15. Important Notes

### Rate Limiting
Frappe does not impose strict rate limits by default, but:
- Large `limit_page_length=0` queries on big tables can be slow
- Reports with large date ranges can timeout
- Batch your requests; do not hammer the API in tight loops

### Naming Series
ERPNext auto-names documents with prefixes:
- Sales Invoice: `SINV-00001`
- Purchase Invoice: `PINV-00001`
- Sales Order: `SO-00001`
- Payment Entry: `PE-00001`
- Journal Entry: `ACC-JV-2026-00001`
- GL Entry: `ACC-GLE-2026-00001`

### Permissions
The API respects ERPNext's role-based permissions. The API key inherits the permissions of the user it was generated for. Our key is for Administrator, which has full access.

### Idempotency
- POST (create) is NOT idempotent -- calling twice creates two documents
- PUT (update) IS idempotent
- Use `name` field or unique constraints to prevent duplicates

### Testing Safely
- Create documents in **Draft** status first (do not submit immediately)
- Use `frappe.client.get_count` to verify before bulk operations
- The Frappe framework maintains a full audit trail -- all changes are logged

### Available Modules
Accounts, Assets, Automation, Buying, Communication, Contacts, Core, CRM, Custom, Desk, EDI, Email, ERPNext Integrations, Geo, GST India, HR, Income Tax India, Integrations, Maintenance, Manufacturing, Payroll, Payments, Payment Gateways, Portal, Print Designer, Printing, Projects, Quality Management, Regional, Selling, Setup, Social, Stock, Subcontracting, Support, Telephony, Utilities, VAT India, Webshop, Website, Workflow
