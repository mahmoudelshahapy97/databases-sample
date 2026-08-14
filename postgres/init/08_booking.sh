#!/usr/bin/env bash
# =============================================================================
# 08_booking.sh  —  Load Booking (Hotel Reservation) into PostgreSQL
# Source: postgres/data/booking/booking_pg.sql
# Target: database booking, schema booking
# =============================================================================
set -euo pipefail

SRC="/source/booking/booking_pg.sql"

echo "------------------------------------------------------"
echo "  Loading: booking.booking  (Hotel Reservation, 7 tables)"
echo "------------------------------------------------------"

{
    echo "SET search_path TO booking;"
    cat "$SRC"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "booking"

echo "booking loaded  ✓  (Room, Amenity, RoomAmenity, Reservation, Guest, GuestReservation, RoomReservation)"
