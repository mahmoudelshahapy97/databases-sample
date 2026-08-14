# Medical Clinic Database Management System

A comprehensive SQL database system for managing medical clinic operations including patient records, appointments, billing, and staff management.

## Overview
This database system was developed as a collaborative project for a graduate-level SQL databases course, demonstrating teamwork and comprehensive database design skills. This system was also developed for supporting essential clinic operations and providing analytical insights for improved patient care and operational efficiency. The project uses simulated data to demonstrate database functionality while maintaining privacy and compliance standards.

## Database Schema
The database consists of 10 interconnected tables:
- **Departments**: Medical and administrative departments
- **MedicalStaff**: Healthcare professionals
- **NonMedicalStaff**: Administrative personnel
- **Patients**: Patient information and demographics
- **Appointments**: Scheduling and visit tracking
- **Prescriptions**: Medication management
- **MedicalRecords**: Patient medical history
- **Billing**: Financial transactions
- **LabReferrals**: Laboratory test management
- **Allergies**: Patient allergy tracking

## Key Features
- Complete patient lifecycle management
- Appointment scheduling and tracking
- Billing and payment processing
- Prescription management
- Lab test coordination
- Staff and department organization
- Comprehensive reporting and analytics

## Database Highlights
- Normalized database design with proper relationships
- Primary and foreign key constraints for data integrity
- Support for complex queries and analytical reporting
- Scalable architecture for growing clinic operations

## Sample Analytics
The database supports various analytical queries including:
- Patient appointment patterns and no-show analysis
- Billing summaries and revenue tracking
- Prescription frequency analysis
- Lab test completion rates
- Staff workload distribution
- Monthly appointment trends

## Technology Stack
- **Database**: MySQL
- **Documentation**: SQL DDL/DML statements
- **Data Analysis**: Complex SQL queries with JOINs, subqueries, and window functions

## Data and Privacy
**Important Note**: This project uses entirely simulated/synthetic data for demonstration purposes. No real patient information, medical records, or personal data is included. All names, addresses, medical conditions, and other details are artificially generated to showcase database functionality while maintaining complete privacy and HIPAA compliance.

## Installation and Setup
1. Create a new MySQL database named `clinic6_db`
2. Run the schema creation scripts in order:
   - `01_create_tables.sql`
   - `02_add_constraints.sql` 
   - `03_alter_tables.sql`
3. Import sample data using the provided CSV files or SQL insert statements
4. Execute analytical queries for reporting

## Project Details
**Development**: Collaborative group project  
**Technology Stack**: MySQL, SQL DDL/DML/DQL  
**Focus**: Healthcare database management and analytics  
**Date**: March 2025

## License
This project is available under the MIT License for educational and reference purposes. All code and documentation are original work created for demonstration of database design and SQL skills.

## Copyright Notice
This project contains original database design, SQL code, and documentation. All simulated data is artificially generated and does not represent any real individuals or medical records.
