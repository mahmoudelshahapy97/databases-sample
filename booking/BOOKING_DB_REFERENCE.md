# Booking.com Environment Database Reference

> Comprehensive reference data for RL training on this Booking.com-like travel booking platform.

**Database:** `data/current.sqlite` (1.9 GB)
**Generated:** January 2, 2026

---

## Quick Statistics

| Entity | Count |
|--------|-------|
| Users | 6,000 |
| Hosts | 13,000 |
| Hotels/Properties | 20,000 |
| Rooms | 39,719 |
| Reviews | 8,091,111 |
| Bookings | 5,193 |
| Transactions | 3,995 |
| Messages | 5,615 |
| Locations | 129 |
| Car Suppliers | 5 |
| Cars | 8 |
| Car Depots | 6 |

---

## Geographic Coverage

### Countries (11)
United States, Germany, United Arab Emirates, Italy, Spain, Japan, Netherlands, France, Singapore, United Kingdom, Thailand

### Cities (20)
| City | Country | Hotels |
|------|---------|--------|
| Berlin | DE | 1,055 |
| Dubai | AE | 1,053 |
| Rome | IT | 1,033 |
| Seattle | US | 1,033 |
| Barcelona | ES | 1,026 |
| Miami | US | 1,021 |
| Tokyo | JP | 1,019 |
| Boston | US | 1,018 |
| Portland | US | 1,016 |
| Denver | US | 997 |
| Amsterdam | NL | 994 |
| Austin | US | 992 |
| Los Angeles | US | 987 |
| San Francisco | US | 983 |
| New York | US | 979 |
| Paris | FR | 977 |
| Singapore | SG | 976 |
| London | GB | 957 |
| Chicago | US | 944 |
| Bangkok | TH | 940 |

### Neighborhoods (79 total)
Manhattan, Brooklyn, Soho, Westminster, Montmartre, Le Marais, Shibuya, Shinjuku, Kreuzberg, Mitte, Queens, Bronx, Staten Island, Harlem, Chelsea, Greenwich Village, Upper East Side, Upper West Side, Tribeca, Financial District, Mission District, Castro, Marina, Pacific Heights, North Beach, Chinatown, Haight-Ashbury, SOMA, Nob Hill, Hollywood, Beverly Hills, Santa Monica, Venice Beach, Downtown LA, West Hollywood, Silver Lake, The Loop, Lincoln Park, Wicker Park, River North, Gold Coast, Camden, Shoreditch, Notting Hill, Covent Garden, Kensington, Mayfair, Canary Wharf, Greenwich, Latin Quarter, Champs-Élysées, Bastille, Belleville, Saint-Germain, Opéra, Ginza, Roppongi, Harajuku, Asakusa, Akihabara, Odaiba, Gothic Quarter, Eixample, Gràcia, Barceloneta, El Born, Jordaan, De Pijp, Vondelpark, Red Light District, Trastevere, Centro Storico, Testaccio, Monti, South Beach, Wynwood, Brickell, Coconut Grove, Little Havana

---

## Property Data

### Property Types
| Type | Count |
|------|-------|
| Hotel | 6,964 |
| Apartment | 5,043 |
| Resort | 1,997 |
| Hostel | 1,595 |
| Guesthouse | 1,346 |
| Villa | 1,030 |
| Bed & Breakfast | 1,011 |
| Motel | 587 |
| Cottage | 427 |

### Star Ratings Distribution
- 5.0 stars: 353 properties
- 4.5-4.9 stars: 3,657 properties
- 4.0-4.4 stars: 3,527 properties
- 3.5-3.9 stars: 3,712 properties
- 3.0-3.4 stars: 3,412 properties
- 2.5-2.9 stars: 2,234 properties
- 2.0-2.4 stars: 2,110 properties
- 1.0-1.9 stars: 995 properties

### Room Types
| Type | Count |
|------|-------|
| Standard | 16,406 |
| Deluxe | 12,210 |
| Family | 4,637 |
| Suite | 4,067 |
| Economy | 902 |
| Executive | 839 |
| Studio | 470 |
| Penthouse | 188 |

### Bed Configurations
| Configuration | Count |
|---------------|-------|
| 1 Queen | 10,212 |
| 1 King | 5,830 |
| 1 Double | 5,768 |
| 2 Double | 5,577 |
| 2 Twin | 5,524 |
| 1 Queen + 2 Twin | 1,586 |
| 1 King + Bunk Bed | 1,491 |
| 2 Queen | 1,390 |
| 1 King + Sofa Bed | 1,335 |

### Room View Types
| View | Count |
|------|-------|
| City View | 11,872 |
| Garden View | 7,913 |
| Ocean View | 6,110 |
| Pool View | 4,005 |
| Courtyard View | 3,932 |
| Mountain View | 3,905 |
| No View | 1,982 |

### Pricing
- **Room base prices:** $20.77 - $2,698.86 (avg: $295.80)
- **Booking totals:** $26.95 - $20,280.65 (avg: $1,557.76)
- **Total booking revenue:** $8,089,430.05

---

## Amenities & Facilities

### Property Amenities (13)
**Activities:** Beach Access, Fitness Center, Swimming Pool
**Property:** BBQ Facilities, Common Area, Private Pool, Shared Kitchen
**Services:** 24-Hour Front Desk, Breakfast Included, Laundry Facilities, Restaurant, Room Service, Self Check-in

### Facilities by Category
| Category | Count |
|----------|-------|
| Gym | 2,043 |
| Pool | 1,565 |
| Restaurant | 1,194 |
| Spa | 769 |
| Bar | 668 |
| Business Center | 502 |

### Property Policies
**Cancellation Policies:**
- Moderate: 7,155
- Strict: 6,164
- Flexible: 4,893
- Non-refundable: 1,788

**Pet Policy:**
- Not Allowed: 10,062
- Allowed: 6,082
- On Request: 3,856

**Smoking Policy:**
- Not Allowed: 12,104
- Designated Areas: 6,839
- Allowed: 1,057

---

## Booking Data

### Booking Status
| Status | Count |
|--------|-------|
| Confirmed | 3,471 |
| Completed | 1,466 |
| Cancelled | 205 |
| No Show | 51 |

### Payment Status
| Status | Count |
|--------|-------|
| Paid | 4,388 |
| Partially Paid | 406 |
| Refunded | 243 |
| Pending | 156 |

### Purpose of Trip
| Purpose | Count |
|---------|-------|
| Business | 2,639 |
| Leisure | 2,554 |

### Date Range
- **Earliest check-in:** 2025-06-11
- **Latest check-in:** 2026-06-06
- **Booking period:** June 2025 - June 2026

### Booking Extras
| Extra Type | Count | Avg Price |
|------------|-------|-----------|
| Breakfast | 1,594 | $15.00 |
| Parking | 1,038 | $25.00 |
| Airport Transfer | 505 | $45.00 |
| Late Checkout | 434 | $50.00 |
| Early Checkin | 404 | $40.00 |
| Spa | 282 | $75.00 |
| Tour | 272 | $60.00 |
| Extra Bed | 256 | $30.00 |
| Other | 134 | $35.00 |

### Cancellation Reasons
| Reason | Count |
|--------|-------|
| Found better accommodation | 28 |
| Weather conditions | 27 |
| Work commitment | 23 |
| Flight cancelled | 23 |
| Trip cancelled | 22 |
| Medical emergency | 21 |
| Price too high | 20 |
| Booking error | 20 |
| Change of plans | 15 |

---

## Review Data

### Volume
- **Total reviews:** 8,091,111
- **Hotels with reviews:** 20,000

### Rating Averages (1-10 scale)
| Category | Average |
|----------|---------|
| Overall | 7.92 |
| Cleanliness | 7.83 |
| Comfort | 7.83 |
| Location | 7.83 |
| Facilities | 7.83 |
| Staff | 7.83 |
| Value | 7.83 |

### Traveler Types
| Type | Reviews | Avg Rating |
|------|---------|------------|
| Friends | 1,619,607 | 7.92 |
| Couple | 1,618,613 | 7.92 |
| Solo | 1,618,048 | 7.92 |
| Business | 1,617,937 | 7.92 |
| Family | 1,616,906 | 7.92 |

---

## User Data

### Users
- **Total users:** 6,000
- **Verified users:** 3,068 (51.1%)
- **Email confirmed:** 6,000 (100%)
- **Country:** All US-based

### Rewards Program
| Tier | Members |
|------|---------|
| Silver | 30 |
| Gold | 14 |
| Platinum | 12 |
| Bronze | 8 |

### Payment Methods
| Card Type | Count |
|-----------|-------|
| Visa | 34 |
| Mastercard | 22 |
| Amex | 16 |
| Discover | 9 |

---

## Host Data

### Host Statistics
- **Total hosts:** 13,000
- **Verified hosts:** 9,147 (70.4%)
- **Superhosts:** 2,615 (20.1%)
- **Average response rate:** 85%
- **Average properties per host:** 9.78

### Host Countries
| Country | Hosts |
|---------|-------|
| Canada | 3,283 |
| United Kingdom | 3,266 |
| United States | 3,239 |
| Australia | 3,212 |

---

## Car Rental System

### Suppliers
| Supplier | Rating | Reviews |
|----------|--------|---------|
| Enterprise | 8.7 | 15,200 |
| Hertz | 8.5 | 12,500 |
| Europcar | 8.2 | 11,200 |
| Avis | 8.3 | 9,800 |
| Budget | 8.0 | 8,700 |

### Car Inventory
| Make | Model | Category | Transmission | Price/Day |
|------|-------|----------|--------------|-----------|
| Toyota | Corolla | Economy | Automatic | $35.00 |
| Ford | Focus | Compact | Automatic | $42.00 |
| Volkswagen | Golf | Compact | Manual | $38.00 |
| Hyundai | Elantra | Mid-size | Automatic | $45.00 |
| Nissan | Rogue | SUV | Automatic | $65.00 |
| BMW | 3 Series | Luxury | Automatic | $95.00 |
| Mercedes-Benz | C-Class | Luxury | Automatic | $105.00 |
| Peugeot | 208 | Economy | Manual | $32.00 |

### Depot Locations
| Depot | City | Type |
|-------|------|------|
| Amsterdam Airport Schiphol | Amsterdam | Airport |
| Amsterdam City Center | Amsterdam | City Center |
| Paris Charles de Gaulle Airport | Paris | Airport |
| Paris City Center | Paris | City Center |
| London Heathrow Airport | London | Airport |
| London City Center | London | City Center |

### Car Features (12)
**Comfort:** Air Conditioning, Automatic Transmission, Cruise Control, Heated Seats, Leather Seats, Sunroof
**Safety:** Backup Camera, Parking Sensors
**Technology:** Bluetooth, GPS Navigation, USB Port
**Performance:** Manual Transmission

---

## Nearby Attractions

### Attraction Types
| Type | Count |
|------|-------|
| Transport | 2,115 |
| Business | 2,058 |
| Museum | 2,021 |
| Other | 2,020 |
| Beach | 2,014 |
| Nature | 1,992 |
| Tourist Attraction | 1,980 |
| Entertainment | 1,959 |
| Restaurant | 1,921 |
| Shopping | 1,920 |

---

## Messaging System

### Message Distribution
| Sender Type | Automated | Count |
|-------------|-----------|-------|
| Guest | No | 2,994 |
| Host | No | 2,369 |
| Host | Yes | 252 |

---

## Images

### Hotel Images
- **Total images:** 81,072
- **Hotels with images:** 20,000 (100%)
- **Categories:** Exterior (20,717), Lobby (20,239), Restaurant (13,489), Pool (13,363), View (13,024)

### Room Images
- **Total images:** 25,395
- **Rooms with images:** 14,029 (35.3%)

---

## Database Schema

### Core Tables (44 total)
**Users & Auth:** users, rewards_program, login_activities, payment_methods
**Properties:** hotels, rooms, hosts, amenities, hotel_amenities, facilities, property_policies, property_charges, nearby_attractions, hotel_images, room_images, check_in_methods
**Bookings:** bookings, booking_extras, booking_checkpoints, booking_requests, order_tokens
**Reviews:** reviews
**Payments:** transactions, cancellations, payouts
**Communication:** messages
**Wishlists:** wishlist_lists, saved_properties
**Search:** search_history
**Locations:** locations
**Rate Plans:** rate_plans, rate_plan_prices
**Car Rentals:** car_suppliers, cars, car_depots, car_features, car_car_features, car_availability, car_images, car_bookings, car_booking_extras
**System:** generation_checkpoints

---

## API Endpoints

### REST API (`/api/*`)
**Hotels:** search, availability, details, amenities, facilities, reviews, images, rooms, policies
**Bookings:** create, get, update, cancel, payments, extras
**Users:** profile, rewards, payment methods, wishlists
**Locations:** countries, cities, regions, search
**Cars:** search, availability, book, manage

### MCP Tools (~56 tools)
**Bookings (10):** booking-preview, cancel-booking, complete-payment, create-booking, get-booking, get-booking-payments, get-user-bookings, mark-booking-messages-read, modify-booking, update-booking

**Hotels (21):** check-hotel-availability, get-featured-hotels, get-filter-counts, get-hotel, get-hotel-amenities, get-hotel-attractions, get-hotel-deals, get-hotel-facilities, get-hotel-images, get-hotel-policies, get-hotel-reviews, get-hotel-reviews-batch, get-hotel-room-types, get-hotel-rooms, get-hotels-details-batch, get-hotels-within-bounds, get-image-url, get-popular-hotels, get-price-distribution, get-property-types, get-random-property-image, search-hotels

**Locations (9):** get-all-countries, get-cities, get-countries, get-location-details, get-location-details-batch, get-location-stats, get-regions, get-trending-locations, search-locations

**Payment Methods (4):** create-payment-method, delete-payment-method, get-user-payment-methods, update-payment-method

**Users (2):** get-current-user, update-user

**Wishlists (9):** add-to-wishlist, check-hotel-saved, create-wishlist, delete-wishlist, get-saved-hotels-batch, get-wishlist-lists, get-wishlists, remove-from-wishlist, rename-wishlist

---

## Sample Data

### Sample Booking
```
Reference: BKWM720376
Guest: Evelyn Mitchell
Hotel: Paddington Boutique Guesthouse - 27 Craven Terrace
City: London
Room: Deluxe
Check-in: 2026-06-05
Check-out: 2026-06-07
Total: $730.52
Status: confirmed / paid
```

### Sample Hotels with Most Reviews
| Hotel | City | Type | Stars | Rating | Reviews |
|-------|------|------|-------|--------|---------|
| Los Feliz Guesthouse | Los Angeles | Guesthouse | 4.0 | 6.47 | 801 |
| Back Bay Victorian B&B | Boston | B&B | 3.9 | 7.94 | 801 |
| Upper East Side Manor | New York | Villa | 4.8 | 7.06 | 801 |
| Skyline Apartment Miami | Miami | Apartment | 4.1 | 8.26 | 800 |
| Beacon Hill Hideaway | Boston | Guesthouse | 3.8 | 8.94 | 800 |
