#!/usr/bin/env bash
# =============================================================================
# 09_mondial.sh  —  Load Mondial (world geography) into MySQL
# Source: mysql/data/mondial/mondial_mysql.sql (schema) + mondial_mysql_data.sql
# Target: database mondial
# =============================================================================
(
set -uo pipefail
. /seed/lib.sh

echo "------------------------------------------------------"
echo "  Loading: mondial  (World geography, 47 tables)"
echo "------------------------------------------------------"

if ! my < /source/mondial/mondial_mysql.sql || ! my < /source/mondial/mondial_mysql_data.sql; then
    seed_failed mondial
    exit 1
fi

report mondial "
    SELECT 'country' AS table_name, COUNT(*) AS rows_loaded FROM country
    UNION ALL SELECT 'province', COUNT(*) FROM province
    UNION ALL SELECT 'city',     COUNT(*) FROM city
    UNION ALL SELECT 'river',    COUNT(*) FROM river
    UNION ALL SELECT 'lake',     COUNT(*) FROM lake
    UNION ALL SELECT 'mountain', COUNT(*) FROM mountain;"

echo "mondial loaded  ✓"
)
