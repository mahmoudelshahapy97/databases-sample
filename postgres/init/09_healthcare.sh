#!/usr/bin/env bash
# =============================================================================
# 09_healthcare.sh  —  Load Healthcare (OpenEMR core) into PostgreSQL
# Source: postgres/data/healthcare/healthcare_pg.sql
# Target: database healthcare, schema healthcare
# =============================================================================
set -euo pipefail

SRC="/source/healthcare/healthcare_pg.sql"

echo "------------------------------------------------------"
echo "  Loading: healthcare.healthcare  (OpenEMR core, 12 tables)"
echo "------------------------------------------------------"

{
    echo "SET search_path TO healthcare;"
    cat "$SRC"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "healthcare"

echo "healthcare loaded  ✓  (facility, users, patient_data, insurance, appointments,"
echo "                        encounters, drugs, prescriptions, immunizations, vitals, billing)"
