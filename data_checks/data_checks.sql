-- First, check if we have data in the tables
SELECT 'teacher_registrations' AS table_name, COUNT(*) AS record_count
FROM yi_assessment.teacher_registration;

-- Then check the submissions table
SELECT 'teacher_submissions' AS table_name, COUNT(*) AS record_count
FROM yi_assessment.teacher_submissions;

-- Check sample results structure from registration table
SELECT 
  'Sample registration result' AS check_type,
  results AS sample_value
FROM yi_assessment.teacher_registration
LIMIT 1;

-- Check sample results structure from submission table
SELECT 
  'Sample submission result' AS check_type,
  results AS sample_value
FROM yi_assessment.teacher_submissions
LIMIT 1;