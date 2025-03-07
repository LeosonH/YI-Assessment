# YI-Assessment

This is a repository for the Youth Impact Data Scientist Assessment. The data model and associated datasets live on Google BigQuery, with credentials provided to the relevant parties. The data dashboard lives here: [Tableau Dashboard](https://public.tableau.com/views/YI_Assessment/Tutorial?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

The data tables are stored in Google BigQuery and are organized as follows:
```
yi-assessment
├── data_model
├── teacher_registration
├── teacher_submissions
```
Access to the [BigQuery project](https://console.cloud.google.com/bigquery?ws=!1m4!1m3!3m2!1syi-assessment!2syi_assessment) has been given to the relevant parties.

The ```data_model``` table is where the final data_model lives. It is created using the BigQuery SQL code applied to the original teacher_registration and teacher_submissions data files. This code is [**data_model.sql**](https://github.com/LeosonH/YI-Assessment/blob/main/data_model.sql). The code first deduplicates the teacher registrations, and then extracts the relevant JSON fields from both datasets before aggregating the data into a school-week long format.

There are three more BigQuery SQL files that live in the **data_checks** directory that provide some templates for tests and data quality checks that were used during the intermediate steps.
[**data_checks.sql**](https://github.com/LeosonH/YI-Assessment/blob/main/data_checks/data_checks.sql) performs rudimentary data quality checks on the original data files.
[**deduplication_checks.sql**](https://github.com/LeosonH/YI-Assessment/blob/main/data_checks/deduplication_checks.sql) helps to debug and verify the deduplication process.
[**json_indexing_checks.sql**](https://github.com/LeosonH/YI-Assessment/blob/main/data_checks/json_indexing_checks.sql) helps to debug and verify the JSON field extraction process.


