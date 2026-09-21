# Amazon S3 in a Data Engineering Pipeline

## 1. What role does S3 play in a Data Engineering pipeline?

A typical AWS data engineering architecture using Python/Pandas + AWS Lambda + S3 can look like:

```text
              External API
                  │
                  ▼
          AWS Lambda + Python
             (Pandas ETL)
                  │
                  ▼
        ┌─────────────────────┐
        │       Amazon S3      │
        │     Data Lake        │
        └─────────────────────┘
           │        │       │
           ▼        ▼       ▼
        Bronze    Silver   Gold
        Raw       Clean    Business
           │        │       │
           └────────┼────────┘
                    ▼
             Athena / Glue
                    │
                    ▼
             BI / Analytics
```

For example, Lambda might:

1. Call an external API such as Spotify.
2. Receive JSON data.
3. Convert JSON to a Pandas DataFrame.
4. Clean and transform the data.
5. Convert the DataFrame to CSV, JSON, or Parquet.
6. Upload the result to S3.
7. A downstream process reads the data from S3.
8. Data is transformed further.
9. Athena, Glue, Spark, Redshift, Databricks, or another analytics system consumes it.

The key idea is:

> **Lambda performs computation/ETL, while S3 provides durable object storage for the data being processed.**

---

# 2. What exactly is Amazon S3?

S3 stands for **Simple Storage Service**.

It is an **object storage service**.

The key word is **object**.

When you upload a file to S3, S3 stores it as an object.

Conceptually:

```text
Object
 ├── Data
 ├── Key
 ├── Metadata
 └── Other properties
```

---

# 3. S3 Bucket

A **bucket** is the top-level container where objects are stored.

For example:

```text
my-data-engineering-bucket
```

Inside it you might have:

```text
my-data-engineering-bucket
│
├── raw/
│   └── spotify/
│       └── 2026-09-21/
│           └── spotify.json
│
├── processed/
│   └── spotify/
│       └── 2026-09-21/
│           └── spotify.csv
│
└── archive/
    └── old_data.csv
```

Think:

```text
Bucket = container
Object = file/data
```

---

# 4. Important: S3 doesn't really have traditional folders

When you see:

```text
raw/spotify/2026-09-21/data.json
```

it looks like:

```text
raw
  └── spotify
       └── 2026-09-21
            └── data.json
```

But S3 fundamentally stores objects using **keys**.

The key is:

```text
raw/spotify/2026-09-21/data.json
```

The `/` is part of the key name.

So technically:

```python
Key = "raw/spotify/2026-09-21/data.json"
```

rather than S3 storing traditional filesystem directories.

---

# 5. Bucket + Key

A bucket and key together identify a specific S3 object.

For example:

```python
Bucket = "my-data-engineering-bucket"

Key = "raw/spotify/2026-09-21/spotify.json"
```

Together:

```text
Bucket
   +
Key
   ↓
Specific S3 object
```

This concept is extremely important when working with boto3.

---

# 6. What is boto3?

**boto3 is the AWS SDK for Python.**

It allows Python programs to communicate with AWS services.

For example:

```python
import boto3
```

Then:

```python
s3_client = boto3.client("s3")
```

Now Python can communicate with S3.

You can perform operations such as:

```text
Upload
Download
Delete
List
Copy
Read metadata
Create bucket
Check bucket
```

---

# 7. Boto3 has two important ways to work with S3

You will frequently see:

```python
boto3.client()
```

and:

```python
boto3.resource()
```

They both allow you to work with S3, but at different abstraction levels.

---

# 8. boto3.client()

Example:

```python
import boto3

s3_client = boto3.client("s3")
```

Think:

> **client = lower-level AWS API interface**

You directly call AWS API operations.

For example:

```python
s3_client.get_object(
    Bucket="my-bucket",
    Key="data/file.csv"
)
```

Or:

```python
s3_client.put_object(
    Bucket="my-bucket",
    Key="data/file.csv",
    Body=data
)
```

The client is extremely common in Lambda.

---

# 9. boto3.resource()

Example:

```python
import boto3

s3_resource = boto3.resource("s3")
```

Think:

> **resource = higher-level, object-oriented interface**

Instead of directly calling API operations, you work with Python objects representing AWS resources.

For example:

```python
bucket = s3_resource.Bucket("my-bucket")
```

Then:

```python
for obj in bucket.objects.all():
    print(obj.key)
```

This is more object-oriented.

---

# 10. Client vs Resource

A simple way to remember:

```text
CLIENT
  ↓
AWS API operations

RESOURCE
  ↓
Python objects representing AWS resources
```

| Client | Resource |
|---|---|
| Lower level | Higher level |
| API-oriented | Object-oriented |
| More direct control | More convenient |
| More operations available | Simplified interface |
| Very common in Lambda | Convenient for object manipulation |

---

# 11. boto3.Session()

There is another important concept:

```python
session = boto3.Session()
```

A session represents your AWS connection/configuration context.

You can then create clients/resources from it:

```python
session = boto3.Session()

s3_client = session.client("s3")

s3_resource = session.resource("s3")
```

You may specify things such as:

```python
session = boto3.Session(
    region_name="ap-south-1"
)
```

For most Lambda applications, you often don't need to explicitly create a session because boto3 can automatically use the Lambda execution role and AWS environment configuration.

---

# 12. How does Lambda authenticate with S3?

This is an important Data Engineer interview question.

You generally **should not put AWS access keys inside your Lambda code**.

Instead:

```text
Lambda
   │
   ▼
IAM Execution Role
   │
   ▼
Permissions
   │
   ▼
S3
```

For example, Lambda's IAM role might allow:

```text
s3:GetObject
s3:PutObject
s3:ListBucket
```

Then your Python code simply does:

```python
s3_client = boto3.client("s3")
```

AWS automatically provides credentials to the Lambda execution environment.

---

# 13. Main S3 operations you need to know

For Data Engineering, learn these categories:

```text
1. Create bucket
2. Upload object
3. Download object
4. Read object
5. List objects
6. Copy object
7. Delete object
8. Check object metadata
9. Generate presigned URL
10. Multipart upload
11. Bucket management
12. Versioning
13. Lifecycle
14. Encryption
15. Access control
```

---

# 14. Creating a bucket

Using client:

```python
s3_client.create_bucket(
    Bucket="my-data-engineering-bucket"
)
```

For regions other than certain defaults, region-specific configuration can be required.

In real projects, buckets are often created through infrastructure-as-code rather than from Lambda.

---

# 15. Uploading a file — upload_file()

One of the most useful methods:

```python
s3_client.upload_file(
    "local_file.csv",
    "my-bucket",
    "raw/data.csv"
)
```

Arguments:

```text
upload_file(
    local_filename,
    bucket,
    s3_key
)
```

Example:

```python
s3_client.upload_file(
    "/tmp/spotify.csv",
    "spotify-data",
    "raw/spotify.csv"
)
```

This uploads:

```text
local machine/Lambda
       │
       ▼
     S3
```

---

# 16. upload_fileobj()

Useful when you have a file-like object:

```python
with open("data.csv", "rb") as f:
    s3_client.upload_fileobj(
        f,
        "my-bucket",
        "raw/data.csv"
    )
```

Very useful when working with:

```text
BytesIO
StringIO
file objects
```

---

# 17. put_object()

Another extremely important method:

```python
s3_client.put_object(
    Bucket="my-bucket",
    Key="raw/data.txt",
    Body="Hello S3"
)
```

Here you're directly providing the object's body.

For example:

```python
data = "customer_id,name\n1,Sagar"

s3_client.put_object(
    Bucket="my-bucket",
    Key="customers.csv",
    Body=data
)
```

---

# 18. upload_file vs put_object

A common interview question.

### upload_file()

```python
s3_client.upload_file(
    "data.csv",
    "bucket",
    "data.csv"
)
```

Used when you have a **local file**.

### put_object()

```python
s3_client.put_object(
    Bucket="bucket",
    Key="data.csv",
    Body=data
)
```

Used when you already have the **data in memory** or as bytes/file-like content.

Think:

```text
upload_file
     ↓
local file → S3

put_object
     ↓
data/body → S3
```

---

# 19. Downloading an object

You can use:

```python
s3_client.download_file(
    "my-bucket",
    "raw/data.csv",
    "/tmp/data.csv"
)
```

Flow:

```text
S3
 │
 ▼
Lambda / local filesystem
```

---

# 20. download_fileobj()

For file-like objects:

```python
with open("/tmp/data.csv", "wb") as f:
    s3_client.download_fileobj(
        "my-bucket",
        "raw/data.csv",
        f
    )
```

---

# 21. get_object()

This is extremely important for ETL.

```python
response = s3_client.get_object(
    Bucket="my-bucket",
    Key="raw/data.csv"
)
```

The response contains information about the object and its body.

For example:

```python
body = response["Body"]
```

The body is a streaming object.

You might do:

```python
data = response["Body"].read()
```

Then:

```python
print(data)
```

---

# 22. Reading S3 data with Pandas

This is especially relevant to a Python/Pandas Lambda project.

You can often do:

```python
import pandas as pd

df = pd.read_csv(
    "s3://my-bucket/raw/data.csv"
)
```

But depending on your environment, Pandas/S3 access commonly requires an S3 filesystem dependency such as `s3fs`.

Alternatively, you can explicitly use boto3:

```python
response = s3_client.get_object(
    Bucket="my-bucket",
    Key="raw/data.csv"
)

df = pd.read_csv(response["Body"])
```

This pattern is particularly useful in Lambda.

---

# 23. Uploading a Pandas DataFrame to S3

Suppose:

```python
df = pd.DataFrame({
    "id": [1, 2, 3],
    "name": ["A", "B", "C"]
})
```

You can convert it to CSV in memory:

```python
import io

csv_buffer = io.StringIO()

df.to_csv(
    csv_buffer,
    index=False
)
```

Then:

```python
s3_client.put_object(
    Bucket="my-bucket",
    Key="processed/data.csv",
    Body=csv_buffer.getvalue()
)
```

The entire flow becomes:

```text
API
 ↓
Lambda
 ↓
JSON
 ↓
Pandas DataFrame
 ↓
Transformations
 ↓
StringIO
 ↓
S3
```

---

# 24. Why /tmp is important in Lambda

Lambda has temporary local storage available through:

```text
/tmp
```

You could do:

```python
df.to_csv("/tmp/data.csv", index=False)
```

Then:

```python
s3_client.upload_file(
    "/tmp/data.csv",
    bucket,
    "processed/data.csv"
)
```

But if the data is reasonably manageable, you can avoid creating a local file and use:

```text
DataFrame
 ↓
StringIO / BytesIO
 ↓
put_object()
 ↓
S3
```

This can simplify serverless ETL.

---

# 25. list_objects_v2()

Suppose your bucket contains:

```text
raw/
 ├── file1.csv
 ├── file2.csv
 └── file3.csv
```

You can list objects:

```python
response = s3_client.list_objects_v2(
    Bucket="my-bucket",
    Prefix="raw/"
)
```

Then:

```python
for obj in response.get("Contents", []):
    print(obj["Key"])
```

Output:

```text
raw/file1.csv
raw/file2.csv
raw/file3.csv
```

---

# 26. Prefix

Prefix is extremely important in S3.

Suppose:

```text
raw/spotify/2026/file1.json
raw/spotify/2026/file2.json
raw/orders/file3.json
```

You can search:

```python
Prefix="raw/spotify/"
```

Then S3 returns objects whose keys begin with:

```text
raw/spotify/
```

Think:

```text
Prefix ≈ filtering objects by beginning of key
```

---

# 27. Important: pagination

Suppose there are thousands or millions of objects.

A single `list_objects_v2()` response doesn't necessarily contain everything.

You need to handle pagination.

The response may contain:

```python
IsTruncated
NextContinuationToken
```

For production code, you can use a boto3 paginator:

```python
paginator = s3_client.get_paginator(
    "list_objects_v2"
)

for page in paginator.paginate(
    Bucket="my-bucket",
    Prefix="raw/"
):
    for obj in page.get("Contents", []):
        print(obj["Key"])
```

This is a very useful interview concept.

---

# 28. Copying an object

Suppose:

```text
raw/data.csv
```

needs to be copied to:

```text
archive/data.csv
```

Using:

```python
copy_source = {
    "Bucket": "my-bucket",
    "Key": "raw/data.csv"
}

s3_client.copy_object(
    CopySource=copy_source,
    Bucket="my-bucket",
    Key="archive/data.csv"
)
```

---

# 29. Moving an object

S3 doesn't have a traditional:

```python
move()
```

operation.

Conceptually:

```text
COPY
 +
DELETE
 =
MOVE
```

Example:

```python
s3_client.copy_object(
    CopySource={
        "Bucket": bucket,
        "Key": "raw/data.csv"
    },
    Bucket=bucket,
    Key="archive/data.csv"
)

s3_client.delete_object(
    Bucket=bucket,
    Key="raw/data.csv"
)
```

---

# 30. delete_object()

Delete one object:

```python
s3_client.delete_object(
    Bucket="my-bucket",
    Key="raw/data.csv"
)
```

---

# 31. delete_objects()

Delete multiple objects:

```python
s3_client.delete_objects(
    Bucket="my-bucket",
    Delete={
        "Objects": [
            {"Key": "file1.csv"},
            {"Key": "file2.csv"}
        ]
    }
)
```

Useful for batch cleanup.

---

# 32. head_object()

Very useful:

```python
response = s3_client.head_object(
    Bucket="my-bucket",
    Key="data.csv"
)
```

It retrieves metadata without downloading the object body.

You can inspect things such as:

```text
ContentLength
ContentType
LastModified
ETag
Metadata
```

Think:

```text
get_object()
    ↓
metadata + actual data

head_object()
    ↓
metadata only
```

---

# 33. Does an object exist?

A common pattern:

```python
try:
    s3_client.head_object(
        Bucket=bucket,
        Key=key
    )
    print("Object exists")

except Exception:
    print("Object doesn't exist")
```

In production, you'd generally handle the relevant AWS error specifically rather than catching every exception.

---

# 34. get_object_tagging()

S3 objects can have tags.

Example:

```python
response = s3_client.get_object_tagging(
    Bucket="my-bucket",
    Key="data.csv"
)
```

Tags might be:

```text
environment = production
department = analytics
data_type = customer
```

Tags can be useful for governance and lifecycle management.

---

# 35. put_object_tagging()

You can add/update tags:

```python
s3_client.put_object_tagging(
    Bucket="my-bucket",
    Key="data.csv",
    Tagging={
        "TagSet": [
            {
                "Key": "environment",
                "Value": "production"
            }
        ]
    }
)
```

---

# 36. S3 metadata

Objects can also have metadata.

For example:

```python
s3_client.put_object(
    Bucket="my-bucket",
    Key="data.csv",
    Body=data,
    Metadata={
        "source": "spotify-api",
        "pipeline": "lambda"
    }
)
```

Then retrieve it with:

```python
head = s3_client.head_object(
    Bucket="my-bucket",
    Key="data.csv"
)

print(head["Metadata"])
```

---

# 37. ContentType

You should sometimes specify the content type.

For example:

```python
s3_client.put_object(
    Bucket=bucket,
    Key="data.json",
    Body=json_data,
    ContentType="application/json"
)
```

For CSV:

```text
ContentType = "text/csv"
```

For Parquet:

```text
ContentType = "application/octet-stream"
```

or an appropriate Parquet content type depending on your application's needs.

---

# 38. S3 Object Versioning

S3 supports **versioning**.

Suppose:

```text
data.csv
```

is uploaded today.

Tomorrow you upload another version.

S3 can preserve previous versions rather than simply losing them.

Conceptually:

```text
data.csv
   │
   ├── Version A
   ├── Version B
   └── Version C
```

This is useful for:

- accidental deletion recovery
- data protection
- auditability
- maintaining previous object versions

---

# 39. S3 Lifecycle

S3 Lifecycle rules automatically manage objects over time.

For example:

```text
0 days
 ↓
S3 Standard

30 days
 ↓
S3 Standard-IA

90 days
 ↓
Glacier

365 days
 ↓
Delete
```

This is useful for data engineering because data often follows:

```text
Hot data
   ↓
Less frequently accessed
   ↓
Archive
   ↓
Delete
```

---

# 40. S3 Storage Classes

Common storage classes include:

```text
S3 Standard
S3 Intelligent-Tiering
S3 Standard-IA
S3 One Zone-IA
S3 Glacier Instant Retrieval
S3 Glacier Flexible Retrieval
S3 Glacier Deep Archive
```

The important concept is:

> Frequently accessed data is generally kept in a suitable active-access storage class, while rarely accessed data can be moved to lower-cost archival classes.

---

# 41. S3 encryption

S3 supports encryption.

Two important server-side encryption concepts are:

### SSE-S3

AWS manages the encryption keys.

```text
Data
 ↓
S3 encryption
 ↓
Encrypted object
```

### SSE-KMS

AWS KMS manages the encryption key.

This provides additional control and auditing capabilities.

You might see:

```python
ServerSideEncryption="aws:kms"
```

and:

```python
SSEKMSKeyId="..."
```

---

# 42. S3 security

Access can be controlled through IAM policies and bucket policies.

For example:

```text
Lambda IAM Role
      │
      ├── s3:GetObject
      ├── s3:PutObject
      └── s3:ListBucket
```

Follow the **least privilege principle**.

If Lambda only needs to upload:

```text
s3:PutObject
```

don't unnecessarily give it broad administrative permissions.

---

# 43. S3 Event Notifications

S3 can trigger downstream processing when objects arrive.

For example:

```text
API
 ↓
Lambda
 ↓
S3
 ↓
Object Created Event
 ↓
Another Lambda
 ↓
Transformation
```

S3 events can integrate with services such as:

```text
Lambda
SQS
SNS
EventBridge
```

This is extremely useful for event-driven data pipelines.

---

# 44. Example: Spotify Data Engineering Pipeline

You could design:

```text
             Spotify API
                  │
                  ▼
             AWS Lambda
                  │
            Python/Pandas
                  │
                  ▼
        ┌────────────────────┐
        │        S3          │
        │                    │
        │ raw/               │
        │ processed/         │
        │ archive/            │
        └────────────┬───────┘
                     │
                     ▼
                 AWS Glue
                     │
                     ▼
                  Athena
                     │
                     ▼
                Power BI
```

---

# 45. Bronze/Silver/Gold with S3

You could structure your bucket as:

```text
spotify-data-lake/
│
├── bronze/
│   └── spotify/
│       └── ingestion_date=2026-09-21/
│           └── data.json
│
├── silver/
│   └── spotify/
│       └── ingestion_date=2026-09-21/
│           └── data.parquet
│
└── gold/
    └── spotify/
        └── ingestion_date=2026-09-21/
            └── top_tracks.parquet
```

This is essentially using S3 as your **data lake storage layer**.

---

# 46. Why Parquet is often better than CSV

For data engineering pipelines, you will often eventually move toward:

```text
CSV
 ↓
Parquet
```

Parquet is:

- columnar
- compressed
- efficient for analytical workloads
- schema-aware
- generally better suited to Athena/Spark/Glue analytical processing

A common layout is:

```text
raw/
   JSON

silver/
   Parquet

gold/
   Parquet
```

---

# 47. Partitioning in S3

You may encounter:

```text
data/year=2026/month=09/day=21/data.parquet
```

This is called a **Hive-style partitioning layout**.

For example:

```text
sales/
├── year=2026/
│   ├── month=08/
│   │   └── data.parquet
│   └── month=09/
│       └── data.parquet
```

This becomes very important with Athena and Glue.

If you query:

```sql
WHERE year = 2026
AND month = 9
```

the query engine can potentially avoid scanning unrelated partitions.

This can reduce:

```text
Data scanned
     ↓
Query cost
     ↓
Query time
```

---

# 48. S3 Select

S3 also has functionality for retrieving only portions of object data in supported formats.

You may encounter:

```python
select_object_content()
```

It allows SQL-like filtering against certain object contents.

However, in modern data engineering architectures, you will more commonly see:

```text
S3
 ↓
Athena / Glue / Spark
```

for analytical querying.

Know S3 Select for awareness, but don't confuse it with Athena.

---

# 49. S3 Transfer Manager

For large or complex transfers, boto3 provides S3 transfer functionality.

For example, `upload_file()` internally handles multipart transfer behavior where appropriate.

This is one reason `upload_file()` is often preferable to manually implementing a large file upload.

---

# 50. Multipart Upload

For large objects, S3 supports multipart upload.

Conceptually:

```text
Large file
     │
     ├── Part 1
     ├── Part 2
     ├── Part 3
     ├── Part 4
     └── Part 5
          │
          ▼
         S3
          │
          ▼
     Combined object
```

Benefits:

- parallel uploads
- better performance
- retry individual parts
- suitable for large files

You don't normally need to manually implement this because boto3 transfer APIs can handle it for you.

---

# 51. S3 Resource example

Suppose you have:

```python
s3_resource = boto3.resource("s3")
```

Then:

```python
bucket = s3_resource.Bucket("my-bucket")
```

Then:

```python
for obj in bucket.objects.all():
    print(obj.key)
```

Here:

```text
boto3
  ↓
resource("s3")
  ↓
Bucket object
  ↓
Objects collection
  ↓
Individual S3 objects
```

---

# 52. S3 Object resource

You can also get a specific object:

```python
obj = s3_resource.Object(
    "my-bucket",
    "raw/data.csv"
)
```

Then:

```python
response = obj.get()
```

and:

```python
data = response["Body"].read()
```

---

# 53. Resource hierarchy

Useful to memorize:

```text
boto3
  │
  ▼
S3 Resource
  │
  ├── Bucket
  │      │
  │      └── Object
  │
  └── Object
```

Example:

```python
s3 = boto3.resource("s3")

bucket = s3.Bucket("my-bucket")

obj = s3.Object(
    "my-bucket",
    "raw/data.csv"
)
```

---

# 54. Important boto3 S3 methods to know

## Bucket-level methods

```python
create_bucket()
delete_bucket()
list_buckets()
head_bucket()
get_bucket_location()
put_bucket_versioning()
get_bucket_versioning()
put_bucket_lifecycle_configuration()
get_bucket_lifecycle_configuration()
```

## Object-level methods

```python
put_object()
get_object()
head_object()
delete_object()
copy_object()
list_objects_v2()
```

## File transfer methods

```python
upload_file()
upload_fileobj()
download_file()
download_fileobj()
```

## Object management

```python
get_object_tagging()
put_object_tagging()
delete_object_tagging()
```

## Advanced methods

```python
get_paginator()
generate_presigned_url()
create_multipart_upload()
upload_part()
complete_multipart_upload()
abort_multipart_upload()
```

You don't need to memorize every method immediately. Understand **what category of operation each performs**.

---

# 55. Presigned URL

S3 objects can be private.

You can generate a temporary URL that provides controlled access.

Example:

```python
url = s3_client.generate_presigned_url(
    "get_object",
    Params={
        "Bucket": "my-bucket",
        "Key": "data.csv"
    },
    ExpiresIn=3600
)
```

The URL expires after:

```text
3600 seconds = 1 hour
```

Useful when you want temporary access without making the bucket/object public.

---

# 56. S3 consistency

Modern S3 provides strong read-after-write consistency for object operations.

Conceptually:

```text
PUT object
   ↓
GET object
   ↓
You can immediately read the latest object
```

This is useful to know when discussing modern S3 architectures.

---

# 57. S3 is not a database

This distinction is very important.

S3 is:

```text
Object storage
```

It is not:

```text
Relational database
```

You don't typically do:

```sql
UPDATE customers
SET name = 'ABC'
WHERE id = 10;
```

directly against S3.

Instead:

```text
S3
 ↓
Data files
 ↓
Athena / Spark / Glue / Redshift etc.
 ↓
SQL / analytics
```

---

# 58. S3 vs Database

| S3 | Database |
|---|---|
| Object storage | Structured data storage |
| Files/objects | Rows/records |
| Massive scalability | Query-oriented |
| Data lake | OLTP/OLAP depending on database |
| Cheap storage | Query/storage model varies |
| CSV/JSON/Parquet | Tables |
| No traditional UPDATE | Supports DML depending on DB |

---

# 59. S3's role in ETL

Your project can be understood as:

## Extract

```text
Spotify API
     ↓
Lambda
```

## Transform

```text
Lambda
 ↓
Python
 ↓
Pandas
 ↓
Cleaning
 ↓
Transformation
```

## Load

```text
Pandas
 ↓
CSV/JSON/Parquet
 ↓
S3
```

So S3 is your **Load destination**.

But S3 can also be the **Extract source** for downstream pipelines:

```text
S3
 ↓
Glue/Spark/Lambda
 ↓
Transformation
 ↓
S3
```

Therefore, S3 can participate in multiple stages of a data pipeline.

---

# 60. Your Lambda + Pandas + S3 architecture

For your specific project:

```text
                    ┌──────────────┐
                    │ Spotify API  │
                    └──────┬───────┘
                           │
                         Extract
                           │
                           ▼
                  ┌─────────────────┐
                  │  AWS Lambda     │
                  │                 │
                  │ Python          │
                  │ Pandas          │
                  └────────┬────────┘
                           │
                        Transform
                           │
                           ▼
              ┌─────────────────────────┐
              │          S3             │
              │                         │
              │  Bronze → Silver → Gold │
              └────────────┬────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Glue / Athena   │
                  └────────┬────────┘
                           │
                           ▼
                    Analytics / BI
```

---

# 61. One complete Lambda example

Suppose your Lambda gets Spotify data:

```python
import boto3
import pandas as pd
import io

s3_client = boto3.client("s3")

def lambda_handler(event, context):

    # 1. Extract
    data = get_spotify_data()

    # 2. Transform
    df = pd.DataFrame(data)

    df = df.drop_duplicates()

    df["popularity"] = df["popularity"].astype(int)

    # 3. Convert DataFrame to CSV in memory
    buffer = io.StringIO()

    df.to_csv(
        buffer,
        index=False
    )

    # 4. Load into S3
    s3_client.put_object(
        Bucket="spotify-data-lake",
        Key="silver/spotify/data.csv",
        Body=buffer.getvalue(),
        ContentType="text/csv"
    )

    return {
        "statusCode": 200,
        "message": "Data loaded successfully"
    }
```

The important flow is:

```text
Spotify
   ↓
Lambda
   ↓
Pandas DataFrame
   ↓
Transformation
   ↓
StringIO
   ↓
put_object()
   ↓
S3
```

---

# 62. Recommended S3 structure for your project

Don't structure your S3 bucket simply like:

```text
bucket/
    data.csv
```

For a Data Engineering project, demonstrate a proper data-lake layout.

For example:

```text
spotify-data-lake/
│
├── raw/
│   └── spotify/
│       └── ingestion_date=2026-09-21/
│           └── spotify_raw.json
│
├── processed/
│   └── spotify/
│       └── ingestion_date=2026-09-21/
│           └── spotify_clean.parquet
│
└── archive/
    └── spotify/
        └── ...
```

This demonstrates that you understand:

- Data lake
- Raw data
- Processed data
- Partitioning
- Object keys
- ETL
- Data lifecycle
- Analytical storage

---

# 63. S3 concepts to know for a Data Engineer interview

## Level 1 — Must know

```text
S3
Bucket
Object
Key
Prefix
boto3
client
resource
upload_file
put_object
get_object
download_file
list_objects_v2
delete_object
copy_object
```

## Level 2 — Strong Data Engineer knowledge

```text
Pagination
Paginators
Multipart upload
Presigned URLs
Versioning
Lifecycle policies
Storage classes
Encryption
IAM
Bucket policies
S3 event notifications
Object metadata
Object tagging
```

## Level 3 — Data Engineering architecture

```text
Data lake
Bronze/Silver/Gold
Partitioning
Parquet
Compression
S3 + Glue
S3 + Athena
S3 + Lambda
S3 + Spark
Event-driven pipelines
Data catalog
Schema evolution
Cost optimization
Data governance
```

---

# 64. The most important mental model

If you remember only one thing, remember this:

```text
                         Boto3
                           │
             ┌─────────────┴─────────────┐
             │                           │
          client                      resource
             │                           │
       AWS API calls                Python objects
             │                           │
             └─────────────┬─────────────┘
                           │
                           ▼
                          S3
                           │
             ┌─────────────┼──────────────┐
             │             │              │
           Bucket        Object          Key
             │             │              │
             └─────────────┼──────────────┘
                           │
                           ▼
                    Data Lake Storage
                           │
        ┌──────────────────┼─────────────────┐
        ▼                  ▼                 ▼
      Bronze             Silver            Gold
        │                  │                 │
       Raw               Clean            Business
        │                  │                 │
        └──────────────────┼─────────────────┘
                           ▼
                   Athena / Glue / Spark
```

And your **Lambda + Pandas** sits primarily on the compute/transformation side:

```text
             COMPUTE                       STORAGE

       AWS Lambda                         Amazon S3
            │                                 │
            │                                 │
         Python                              Files
            │                              Objects
         Pandas                               │
            │                                 │
            └──────────────►──────────────────┘
                    ETL / Data flow
```

---

# 65. Interview-ready answer

If an interviewer asks:

**"What is the role of S3 in your data engineering project?"**

A strong answer would be:

> "I use Amazon S3 as the object-storage layer and data lake for my pipeline. AWS Lambda performs the extraction and Pandas-based transformations, and the resulting raw or processed datasets are stored in S3. I organize the data using prefixes such as raw, processed, and archive, and can use partitioned paths and formats such as Parquet for downstream analytics. I interact with S3 from Python using boto3, primarily through the S3 client methods such as `get_object`, `put_object`, `upload_file`, `list_objects_v2`, and `delete_object`. Lambda accesses S3 through an IAM execution role rather than hard-coded credentials. Downstream services such as Glue, Athena, or Spark can then consume the data from S3."

This answer demonstrates that you understand **S3 as part of an actual data engineering architecture**, rather than simply knowing how to upload a file.

---

# Quick Revision Cheat Sheet

```text
S3
│
├── Bucket
│     └── Object
│           └── Key
│
├── boto3
│     ├── client()
│     └── resource()
│
├── Upload
│     ├── upload_file()
│     ├── upload_fileobj()
│     └── put_object()
│
├── Download / Read
│     ├── download_file()
│     ├── download_fileobj()
│     └── get_object()
│
├── List
│     ├── list_objects_v2()
│     └── get_paginator()
│
├── Object management
│     ├── copy_object()
│     ├── delete_object()
│     ├── head_object()
│     └── tagging
│
├── Security
│     ├── IAM
│     ├── Bucket Policies
│     ├── Encryption
│     └── Least Privilege
│
├── Data Lake
│     ├── Bronze
│     ├── Silver
│     └── Gold
│
├── Data Engineering
│     ├── JSON / CSV / Parquet
│     ├── Partitioning
│     ├── Glue
│     ├── Athena
│     └── Spark
│
└── Advanced
      ├── Versioning
      ├── Lifecycle
      ├── Storage Classes
      ├── Event Notifications
      ├── Presigned URLs
      └── Multipart Upload
```

## Core mental model

```text
Lambda = Compute / ETL
Pandas = Transformation
S3 = Storage / Data Lake
Glue = Catalog / ETL
Athena = Query
Spark = Distributed Processing
IAM = Access Control
```

Together:

```text
Source
  ↓
Lambda
  ↓
Pandas
  ↓
S3
  ↓
Glue / Athena / Spark
  ↓
Analytics
```
