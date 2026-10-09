#!/usr/bin/env bash
# =============================================================================
# 07_healthcare.sh  —  Load Healthcare (OpenEMR core) into MySQL
# Source: mysql/data/healthcare/healthcare.sql
# Target: database healthcare
# =============================================================================
(
set -uo pipefail
. /seed/lib.sh

echo "------------------------------------------------------"
echo "  Loading: healthcare  (OpenEMR core, 12 tables)"
echo "------------------------------------------------------"

if ! my < /source/healthcare/healthcare.sql; then
    seed_failed healthcare
    exit 1
fi

report healthcare "
    SELECT 'facility'          AS table_name, COUNT(*) AS rows_loaded FROM facility
    UNION ALL SELECT 'users',                 COUNT(*) FROM users
    UNION ALL SELECT 'patient_data',          COUNT(*) FROM patient_data
    UNION ALL SELECT 'insurance_companies',   COUNT(*) FROM insurance_companies
    UNION ALL SELECT 'insurance_data',        COUNT(*) FROM insurance_data
    UNION ALL SELECT 'appointments',          COUNT(*) FROM appointments
    UNION ALL SELECT 'form_encounter',        COUNT(*) FROM form_encounter
    UNION ALL SELECT 'drugs',                 COUNT(*) FROM drugs
    UNION ALL SELECT 'prescriptions',         COUNT(*) FROM prescriptions
    UNION ALL SELECT 'immunizations',         COUNT(*) FROM immunizations
    UNION ALL SELECT 'form_vitals',           COUNT(*) FROM form_vitals
    UNION ALL SELECT 'billing',               COUNT(*) FROM billing;"

echo "healthcare loaded  ✓"
)
