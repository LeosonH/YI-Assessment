WITH 
-- Extract school information from registration data
-- The results field is a JSON array
teacher_info AS (
  SELECT
    id AS teacher_id,
    inserted_at,
    EXTRACT(WEEK FROM CAST(inserted_at AS TIMESTAMP)) AS week,
    -- Extract values using proper JSON paths
    (SELECT JSON_EXTRACT_SCALAR(item, '$.value') 
     FROM UNNEST(JSON_EXTRACT_ARRAY(results)) AS item 
     WHERE JSON_EXTRACT_SCALAR(item, '$.label') = 'teacher_division') AS division,
    (SELECT JSON_EXTRACT_SCALAR(item, '$.value') 
     FROM UNNEST(JSON_EXTRACT_ARRAY(results)) AS item 
     WHERE JSON_EXTRACT_SCALAR(item, '$.label') = 'teacher_district') AS district,
    (SELECT JSON_EXTRACT_SCALAR(item, '$.value') 
     FROM UNNEST(JSON_EXTRACT_ARRAY(results)) AS item 
     WHERE JSON_EXTRACT_SCALAR(item, '$.label') = 'teacher_block') AS block,
    (SELECT JSON_EXTRACT_SCALAR(item, '$.value') 
     FROM UNNEST(JSON_EXTRACT_ARRAY(results)) AS item 
     WHERE JSON_EXTRACT_SCALAR(item, '$.label') = 'teacher_cluster') AS cluster,
    (SELECT JSON_EXTRACT_SCALAR(item, '$.value') 
     FROM UNNEST(JSON_EXTRACT_ARRAY(results)) AS item 
     WHERE JSON_EXTRACT_SCALAR(item, '$.label') = 'teacher_school') AS school
  FROM yi_assessment.teacher_registration
),

-- Deduplicate teachers (keep most recent registration)
deduped_teachers AS (
  SELECT
    teacher_id,
    inserted_at,
    week,
    division,
    district, 
    block,
    cluster,
    school,
    ROW_NUMBER() OVER (
      PARTITION BY teacher_id 
      ORDER BY inserted_at DESC
    ) AS row_num
  FROM teacher_info
),

-- Level mapping for baseline and endline assessments
level_mapping AS (
  SELECT * FROM UNNEST([
    STRUCT('Beginner' AS level, 0 AS value),
    STRUCT('Addition' AS level, 1 AS value),
    STRUCT('Subtraction' AS level, 2 AS value),
    STRUCT('Multiplication' AS level, 3 AS value),
    STRUCT('Division' AS level, 4 AS value)
  ])
),

-- Extract baseline assessments
baseline_assessments AS (
  SELECT
    contact_id,
    inserted_at,
    EXTRACT(WEEK FROM CAST(inserted_at AS TIMESTAMP)) AS week,
    JSON_EXTRACT_SCALAR(results, '$.bl_lt_confirm.category') AS bl_lt_confirm,
    JSON_EXTRACT_SCALAR(results, '$.bl_student_level.category') AS bl_student_level
  FROM yi_assessment.teacher_submissions
  WHERE name = '02_B_Baseline LT MAIN'
    AND LOWER(JSON_EXTRACT_SCALAR(results, '$.bl_lt_confirm.category')) = 'yes'
),

-- Extract tutoring calls
tutoring_calls AS (
  SELECT
    contact_id,
    inserted_at,
    EXTRACT(WEEK FROM CAST(inserted_at AS TIMESTAMP)) AS week
  FROM yi_assessment.teacher_submissions
  WHERE name = '03_B_IMPL LT MAIN'
    AND LOWER(JSON_EXTRACT_SCALAR(results, '$.impl_lt_confirm.category')) = 'yes'
),

endline_assessments AS (
  SELECT
    contact_id,
    inserted_at,
    EXTRACT(WEEK FROM CAST(inserted_at AS TIMESTAMP)) AS week,
    JSON_EXTRACT_SCALAR(results, '$.el_lt_confirm.category') AS el_lt_confirm,
    JSON_EXTRACT_SCALAR(results, '$.el_student_level.category') AS el_student_level
  FROM yi_assessment.teacher_submissions
  WHERE name = '04_B_ENDLINE LT MAIN'
    AND LOWER(JSON_EXTRACT_SCALAR(results, '$.el_lt_confirm.category')) = 'yes'
),

-- Aggregate teachers by school and week
teachers_by_school_week AS (
  SELECT
    division,
    district,
    block,
    cluster,
    school,
    week,
    COUNT(DISTINCT teacher_id) AS teachers_registered
  FROM deduped_teachers
  WHERE row_num = 1  -- Keep only most recent registration
    AND school IS NOT NULL
  GROUP BY division, district, block, cluster, school, week
),

-- Aggregate baseline assessments by school and week
baseline_by_school_week AS (
  SELECT
    t.division,
    t.district,
    t.block,
    t.cluster,
    t.school,
    b.week,
    COUNT(DISTINCT b.contact_id) AS baseline_assessments,
    AVG(COALESCE(m.value, 0)) AS baseline_average_level
  FROM baseline_assessments b
  JOIN deduped_teachers t 
    ON b.contact_id = t.teacher_id AND t.row_num = 1
  LEFT JOIN level_mapping m 
    ON b.bl_student_level = m.level
  WHERE t.school IS NOT NULL
  GROUP BY t.division, t.district, t.block, t.cluster, t.school, b.week
),

-- Aggregate tutoring calls by school and week
tutoring_by_school_week AS (
  SELECT
    t.division,
    t.district,
    t.block,
    t.cluster,
    t.school,
    c.week,
    COUNT(DISTINCT c.contact_id) AS tutoring_calls
  FROM tutoring_calls c
  JOIN deduped_teachers t 
    ON c.contact_id = t.teacher_id AND t.row_num = 1
  WHERE t.school IS NOT NULL
  GROUP BY t.division, t.district, t.block, t.cluster, t.school, c.week
),

-- Aggregate endline assessments by school and week
endline_by_school_week AS (
  SELECT
    t.division,
    t.district,
    t.block,
    t.cluster,
    t.school,
    e.week,
    COUNT(DISTINCT e.contact_id) AS endline_assessments,
    AVG(COALESCE(m.value, 0)) AS endline_average_level
  FROM endline_assessments e
  JOIN deduped_teachers t 
    ON e.contact_id = t.teacher_id AND t.row_num = 1
  LEFT JOIN level_mapping m 
    ON e.el_student_level = m.level
  WHERE t.school IS NOT NULL
  GROUP BY t.division, t.district, t.block, t.cluster, t.school, e.week
)

-- Combine all metrics into final result
SELECT
  t.division,
  t.district,
  t.block,
  t.cluster,
  t.school,
  t.week,
  t.teachers_registered,
  COALESCE(b.baseline_assessments, 0) AS baseline_assessments,
  COALESCE(b.baseline_average_level, 0) AS baseline_average_level,
  COALESCE(c.tutoring_calls, 0) AS tutoring_calls,
  COALESCE(e.endline_assessments, 0) AS endline_assessments,
  COALESCE(e.endline_average_level, 0) AS endline_average_level
FROM teachers_by_school_week t
LEFT JOIN baseline_by_school_week b 
  ON t.division = b.division
  AND t.district = b.district
  AND t.block = b.block
  AND t.cluster = b.cluster
  AND t.school = b.school
  AND t.week = b.week
LEFT JOIN tutoring_by_school_week c
  ON t.division = c.division
  AND t.district = c.district
  AND t.block = c.block
  AND t.cluster = c.cluster
  AND t.school = c.school
  AND t.week = c.week
LEFT JOIN endline_by_school_week e
  ON t.division = e.division
  AND t.district = e.district
  AND t.block = e.block
  AND t.cluster = e.cluster
  AND t.school = e.school
  AND t.week = e.week
ORDER BY t.division, t.district, t.block, t.cluster, t.school, t.week