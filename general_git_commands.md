# Spark Transformations

## What is a Transformation?

A transformation creates a **new DataFrame** from an existing DataFrame.

### Types

1. Narrow Transformation
2. Wide Transformation

### Example

```python
df.filter(col("age") > 18)
```

### Key Points

- Lazy Evaluation
- Immutable
- Returns a new DataFrame
