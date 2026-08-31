# Section 1

Question 1 of 5 (easy): In your own words, what does the Driver actually do in a Spark application — and what's the key thing it does not do, that people sometimes mistakenly think it does?

---

Question 2 of 5 (easy): What's the difference between a Worker Node and an Executor?

---

Question 3 of 5 (medium): Suppose you read a file into a DataFrame that has 6 partitions, call .filter() to drop some rows, then .select() to keep only a few columns, and finally call .show(). How many stages does this create, and how many tasks would be in that stage? Explain your reasoning.

---

Question 4 of 5 (medium-hard): Take that same scenario, but now add .groupBy("some_column").count() right after .select(), still before .show(). How many stages does the job have now, and why did it change?

---
Question 5 of 5 (hard): Put it all together. Walk me through, step by step, exactly what happens from the moment spark-submit runs to the moment results are printed, for a job that reads data, filters it, groups by a key, and calls .show(). Use the terms Driver, Cluster Manager, Executor, Job, Stage, and Task correctly as you go.

---
# Section 2


