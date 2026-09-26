# Snowflake Stages and Data Loading
![alt text](image-4.png)
![Image 5](image-5.png)

- One of the key features of Snowflake is the ability to load data from external sources into tables using stages and the COPY command. This is how data gets into your warehouse, whether from S3, Azure Blob Storage, or Google Cloud Storage.

![alt text](image-6.png)

 ## What are Stages in Snowflake

 - Stages are named locations that provide a way to access files from Snowflake. They act as a bridge between your external storage (like an S3 bucket) and your Snowflake tables.
 - There are two types:
    - Internal stages: Created and managed within Snowflake. Files are uploaded directly to Snowflake's internal storage.
    - External stages: Point to locations outside Snowflake (S3, GCS, Azure Blob). Snowflake reads files from these locations without moving them.

## Setting up the environment
- First, create a database and schema to manage your stage objects and file formats:
```sql
create or replace database my_db;

create or replace schema my_schema;
```
- creating stages:
   - Internal stage:
   ```sql
   create or replace stage my_internal_stage;
   ```
   External stage:
   ```sql
   create or replace stage my_external_stage
   url = 's3://your-bucket-name'
   credentials = (aws_key_id = '' aws_secret_key = '')

   # You can also use publically accessible bucket, where credentials are not required
   create or replace stage my_external_stage
   url = 's3://your-public-bucket-name'
   ```
- Useful Stage commands:
```sql
-- Describe the stage to see its properties
DESC STAGE my_db.my_schema.aws_stage;

-- List files in the stage
LIST @aws_stage;

-- Update/modify stage credentials
ALTER STAGE aws_stage
    SET credentials=(aws_key_id='XYZ_DUMMY_ID' aws_secret_key='987xyz');
```

## Loading data with copy- Basic copy command
- First create a target table
```sql
CREATE OR REPLACE TABLE my_db.public.orders (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30)
);
```
- Then load data from the stage using COPY INTO:
```sql
COPY INTO MANAGE_DB.PUBLIC.ORDERS
FROM @aws_stage
file_format = (type = csv field_delimiter = ',' skip_header=1)
files=('OrderDetails.csv');

SELECT * FROM my_db.public.orders;

```

## Transformations During Loading
```sql
CREATE OR REPLACE TABLE my_db.public.orders_new (
    ORDER_ID VARCHAR(30),
    AMOUNT INT
);

COPY INTO my_db.public.orders_new
FROM (SELECT s.$1, s.$2 FROM @my_db.external_stages.aws_stage s)
file_format = (type = csv field_delimiter = ',' skip_header=1)
files=('OrderDetails.csv');

SELECT * FROM my_db.public.orders_new;

```
- Apply case logic during loading
```sql
CREATE OR REPLACE TABLE my_db.public.orders_new1 (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    PROFITABILITY VARCHAR(255)
);

COPY INTO my_db.public.orders_new1
FROM (SELECT
        s.$1,
        s.$2,
        s.$3,
        CASE WHEN CAST(s.$3 as int) < 0 THEN 'not profitable' ELSE 'profitable' END
      FROM @MANAGE_DB.external_stages.aws_stage s)
file_format = (type = csv field_delimiter=',' skip_header=1)
files=('OrderDetails.csv');

SELECT * FROM my_db.public.orders_new1;
```

# Creating File Formats
- When loading data into Snowflake, you need to tell it how to parse the incoming files. File format objects define the structure, delimiters, compression, header rows, etc. Instead of specifying these properties inline every time you run a COPY command, you create a reusable file format object.

## Setting up a file format
- Create a dedicated schema to keep file format objects organized:
```sql
create or replace schema file_format
```
- Creating File Format Objects
```sql
create or replace file format csv_file_format
type = csv
field_delimiter = ','
skip_header = 1;
```
- If you not mentioned any particular type it will create csv type file format. Once a file format is created, you cannot alter the type. This will fail.
- You can inspect file format using
```sql
desc file format mydb.file_format.csv_file_format;
``` 
- You can alter:
```sql
alter file format mydb.file_format.csv_file_format
set skip_header = 0;
```
- Other types of file formats:
```sql
create or replace file format json_file_format
type = json
compression = auto;
----------------------------------
create or replace file format parquet
type = parquet
compression = auto
-----------------------------------
create or replace file format avro
type = avro
compression = auto
```

