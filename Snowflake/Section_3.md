# Understanding Snowpipe
- So far, we have been loading data manually using `COPY INTO`. But in production, data files land in S3 continuously, new CSV files every minute, every hour. You don't want to run COPY commands manually or even schedule them. Snowpipe solves this by automatically ingesting data as soon as new files arrive.

## What is Snowpipe?
- Snowpipe is a cloud-based serverless service that enables real-time data ingestion into Snowflake tables. When a new file lands in your S3 bucket (or GCS/Azure), Snowpipe detects it and automatically loads it into your table, no manual intervention, no scheduled jobs.
- It works by:
    - S3 sends an event notification when a new file is uploaded
    - Snowpipe receives the notification via an SQS queue
    - Snowpipe runs the `COPY INTO` command automatically
    - Data appears in your snowflake table within seconds to minutes

## Snowpipe Syntax
```sql
CREATE PIPE <pipe_name>
    AUTO_INGEST = { TRUE | FALSE }
    AS
    COPY INTO <table_name>
    FROM @<stage_name>
    PATTERN = '<file_name_pattern>'
    [ ON_ERROR = 'CONTINUE' | 'ABORT_STATEMENT' ]
    [ PURGE = TRUE | FALSE ]
```
- Key parameters:
    - `AUTO_INGEST = TRUE:` Snowpipe automatically detects and loads new files. Set to FALSE if you want to trigger loading manually via REST API.
    - `ON_ERROR:` What to do on errors: `CONTINUE` skips bad files, `ABORT_STATEMENT` stops the load.
    - `PURGE:` Delete files from the stage after successful loading.

## Setting Up Snowpipe

- Step 1 — Create the Target Table
```sql
create or replace table mydb.public.employees(
    id int,
    first_name string,
    last_name string,
    email string,
    location string,
    department string
);
```
- Step 2 - Create file format
```sql
create or replace file format mydb.file_format.csv_file_format
type = csv
field_delimiter = ','
skip_header = 1
null_if = ('NULL','null')
empty_field_as_null = True;
```
- Step 3 - Create stage with storage integration
```sql
create or replace stage mydb.my_external_stage.aws_stage
url = 's3://bucket-path'
storage_integration = name of your storage integration
file_format = your specified file format

--- verify if file are accessible using list command
list @your stage name
```
- Step 4 - Create the Pipe
```sql
---first we create schema for our pipe

create or replace schema mydb.pipes;

create or replace pipe mydb.pipes.employees_pipe
auto_ingest = True
as
copy into mydb.public.employees
from @mydb.external_stage.aws_stage;
```
- Step 5 - Configuring s3 event notifications using SQS Queue
- Step 6 - Verify
```sql
select * from mydb.public.employees;

--- It will fetch file records from s3. After running above command upload another file with same structure in your bucket and see if snowpipe is fetching the records automatically.
```
## Storage Integration

- A storage integration is a Snowflake object that stores the connection details for accessing an external cloud storage location (S3, GCS, Azure Blob). Instead of embedding credentials in every stage, you create one integration and reference it across multiple stages.
- Benefits:
    - No hardcoded credentials: Uses IAM role-based access instead of access keys
    - Centralized management: Update credentials in one place, not in every stage
    - Restricted locations: STORAGE_ALLOWED_LOCATIONS limits which buckets Snowflake can access
    - Auditable: Integration objects are tracked and can be governed by Snowflake roles
- Step 1 - Create the Storage Integration
```sql
CREATE OR REPLACE STORAGE INTEGRATION s3_init
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::2034864637456:role/snowflake-s3-connection'
  STORAGE_ALLOWED_LOCATIONS = ('s3://dw-snowflake-course-darshil')
  COMMENT = 'Creating connection to S3';
```
- For further follow the snowpipe steps.


## copy vs snowpipe
- Use COPY INTO for batch loading, scheduled ETL jobs, initial data loads, backfills. Use Snowpipe for continuous ingestion, streaming data, real-time file drops, event-driven pipelines. They use the same COPY syntax under the hood, but Snowpipe automates the trigger.

## cost model
- Snowpipe uses a serverless compute model, you don't need a running virtual warehouse. Snowflake manages the compute and charges per file loaded. This is cheaper than keeping a warehouse running 24/7 waiting for files, but can add up if you're loading millions of tiny files. For very high-volume ingestion, consider batching files before uploading.