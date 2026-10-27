# Declarative Pipelines in Darabricks (aka Delta Live Tables)

- It is a framework in datatbricks used to build, manage and automate reliable data pipelines for batch and streaming data. It simplifies building and maintaining data pipelines by automating data processing, dependency management and data quality checks.
- Declarative Pipeline in databricks also known as Delta Live Tables(DLT). These are modern way to build data pipelines using simple SQL or Python code with less manual orchestration and more automation.
- You just declare what you want. and DLT will take care how it should be done.
- Benefits:
    - **Quality Checks**: 
        - DLT supports something called expectations where you can define rules (like "this column should never be null"). If a record breaks the rule, DLT will drop it or send it to quarantine. You dont need to write extra code to handle this.
    - **Automatic Dependency Management**:
        - You dont need to worry about the order of transformations. Just define your tables and DLT figures out which table depends on which and runs thing in correct order.
    - **Incremental Proceesing**: DLT is smart it only processes new or changed data using CDC
    - **Unified Batch and Streaming**: Normally batch and straming pipelines are built and maintained separately. But with DLT you can use same code for both. It detects your data source is streaming and handles it accordingly.
## Key Components:
1. Streaming Table
2. Materialized View
3. Views
    - a. Batch Views
    - b. Streaming Views