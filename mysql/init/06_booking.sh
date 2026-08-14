#!/usr/bin/env bash
# =============================================================================
# 06_booking.sh  —  Load Booking (Hotel Reservation) into MySQL
# Source: mysql/data/booking/booking.sql
# Target: database booking
# =============================================================================
(
set -uo pipefail
. /seed/lib.sh

echo "------------------------------------------------------"
echo "  Loading: booking  (Hotel Reservation, 7 tables)"
echo "------------------------------------------------------"

if ! my < /source/booking/booking.sql; then
    seed_failed booking
    exit 1
fi

report booking "
    SELECT 'room'            AS table_name, COUNT(*) AS rows_loaded FROM room
    UNION ALL SELECT 'amenity',             COUNT(*) FROM amenity
    UNION ALL SELECT 'roomamenity',         COUNT(*) FROM roomamenity
    UNION ALL SELECT 'guest',               COUNT(*) FROM guest
    UNION ALL SELECT 'reservation',         COUNT(*) FROM reservation
    UNION ALL SELECT 'guestreservation',    COUNT(*) FROM guestreservation
    UNION ALL SELECT 'roomreservation',     COUNT(*) FROM roomreservation;"

echo "booking loaded  ✓  (18 rooms, 11 guests, 25 reservations)"
)
