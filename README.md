# YI-Assessment

This is a repository for the Youth Impact Data Scientist Assessment. The data model and associated datasets live on Google BigQuery, with credentials provided to the relevant parties. The data dashboard lives here: [Tableau Dashboard](https://public.tableau.com/views/YI_Assessment/Tutorial?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

The data tables on Big Query are organized as follows:
```
yi-assessment
├── data_model
├── teacher_registration
├── teacher_submissions
```
The ```data_model``` table is where the final data_model lives. It is created using the BigQuery SQL code applied to the original teacher_registration and teacher_submissions data files. This code is [**data_model.sql**](https://github.com/LeosonH/YI-Assessment/blob/main/data_model.sql).
