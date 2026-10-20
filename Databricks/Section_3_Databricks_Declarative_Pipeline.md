# Declarative Pipelines in Darabricks

- Declarative Pipeline in databricks also known as Delta Live Tables(DLT). These are modern way to build data pipelines using simple SQL or Python code with less manual orchestration and more automation.
- You just declare what you want. and DLT will take care how it should be done.
- Benefits:
    - **Quality Checks**: 
    - **Automatic Dependency Management**:
    - **Incremental Proceesing**: DLT is smart it only processes new or changed data using CDC
    - **Unified Batch and Streaming**: Normally batch and straming pipelines are built and maintained separately. But with DLT you can use same code for both. It detects your data source is streaming and handles it accordingly.