-- Debug endline assessments
SELECT 
  name,
  COUNT(*) as count
FROM yi_assessment.teacher_submissions
WHERE name LIKE '%ENDLINE%'
GROUP BY name;

-- If we find records, let's check their structure
SELECT 
  name,
  results,
  JSON_EXTRACT_SCALAR(results, '$.bl_lt_confirm.category') AS bl_lt_confirm,
  JSON_EXTRACT_SCALAR(results, '$.el_lt_confirm.category') AS el_lt_confirm,
  JSON_EXTRACT_SCALAR(results, '$.el_student_level.category') AS el_student_level
FROM yi_assessment.teacher_submissions
WHERE name = '04_B_ENDLINE LT MAIN'
LIMIT 5;