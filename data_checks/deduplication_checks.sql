WITH 
-- First, deduplicate the teacher registration data
deduped_registrations AS (
  SELECT
    id AS teacher_id,
    inserted_at,
    results,
    -- Use ROW_NUMBER to rank multiple registrations for the same teacher
    ROW_NUMBER() OVER (
      PARTITION BY id 
      ORDER BY inserted_at DESC  -- Keep the most recent registration
    ) AS row_num
  FROM yi_assessment.teacher_registration
)

SELECT
    teacher_id,
    inserted_at,
    -- Extract week from inserted_at
    EXTRACT(WEEK FROM CAST(inserted_at AS TIMESTAMP)) AS week
  FROM deduped_registrations
  WHERE row_num = 1  -- Only include the most recent record for each teacher
LIMIT 10