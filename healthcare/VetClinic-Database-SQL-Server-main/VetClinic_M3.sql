--=============================================
-- VetClinic_M3 || Malak Zahda || 22310028
--=============================================

--STEP 1: Create Database 
CREATE DATABASE VetClinic_M3;
USE VetClinic_M3;

--STEP 2: Create Schemas
CREATE SCHEMA Core
GO
CREATE SCHEMA Finance
GO

--=============================================
-- STEP 3: CREATE TABLES 
--=============================================

--TABLE 1: Species (Core)
CREATE TABLE Core.Species (
    SpeciesID INT PRIMARY KEY,
    SpeciesName VARCHAR(50) NOT NULL UNIQUE
);

--TABLE 2: Customer (Core)
CREATE TABLE Core.Customer (
    CustomerID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Address TEXT,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Inactive', 'Suspended'))
);

-- TABLE 3: Staff (Core) 
CREATE TABLE Core.Staff (
    StaffID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Role VARCHAR(50) NOT NULL,
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Inactive', 'On Leave'))
);

-- TABLE 4: Service (Core) 
CREATE TABLE Core.Service (
    ServiceID INT PRIMARY KEY,
    ServiceName VARCHAR(100) NOT NULL UNIQUE,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    CostPrice DECIMAL(10,2) NOT NULL CHECK (CostPrice >= 0),
    Category VARCHAR(50) NOT NULL,
    CONSTRAINT CHK_Service_Price_GreaterThan_Cost 
        CHECK (Price >= CostPrice)
);

-- TABLE 5: Medication (Finance)
CREATE TABLE Finance.Medication (
    MedicationID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    CostPrice DECIMAL(10,2) NOT NULL CHECK (CostPrice >= 0),
    Unit VARCHAR(20) NOT NULL DEFAULT 'Tablet',
    CONSTRAINT CHK_Medication_Price_GreaterThan_Cost 
        CHECK (Price >= CostPrice)
);

-- TABLE 6: Vaccine (Core)
CREATE TABLE Core.Vaccine (
    VaccineID INT PRIMARY KEY,
    VaccineName VARCHAR(100) NOT NULL UNIQUE,
    Duration INT NOT NULL,
    Description TEXT
);

-- TABLE 7: Breed (Core)
CREATE TABLE Core.Breed (
    BreedID INT PRIMARY KEY,
    BreedName VARCHAR(50) NOT NULL,--ليس مميز لانه قد يكون لعدة حيوانات نفس اسم السلالة
    SpeciesID INT NOT NULL,
    UNIQUE (BreedName, SpeciesID),
    FOREIGN KEY (SpeciesID) REFERENCES Core.Species(SpeciesID)
);

-- TABLE 8: Animal (Core)
CREATE TABLE Core.Animal (
    AnimalID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    BreedID INT NOT NULL,
    Name VARCHAR(50) NOT NULL,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')),
    BirthDate DATE,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Deceased', 'Adopted Out', 'In Treatment')),
    FOREIGN KEY (CustomerID) REFERENCES Core.Customer(CustomerID),
    FOREIGN KEY (BreedID) REFERENCES Core.Breed(BreedID)
);

-- TABLE 9: Inventory (Finance)
CREATE TABLE Finance.Inventory (
    InventoryID INT PRIMARY KEY,
    MedicationID INT NOT NULL UNIQUE,
    Quantity INT NOT NULL CHECK (Quantity >= 0),
    ExpiryDate DATE NOT NULL,
    FOREIGN KEY (MedicationID) REFERENCES Finance.Medication(MedicationID)
);

-- TABLE 10: Visit (Core)
CREATE TABLE Core.Visit (
    VisitID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Scheduled' 
        CHECK (Status IN ('Scheduled', 'In Progress', 'Completed', 'Cancelled')),
    Note TEXT,
    FOREIGN KEY (CustomerID) REFERENCES Core.Customer(CustomerID)
);

-- TABLE 11: Examination (Core)
CREATE TABLE Core.Examination (
    ExamID INT PRIMARY KEY,
    VisitID INT NOT NULL UNIQUE,
    StaffID INT NOT NULL,
    AnimalID INT NOT NULL,
    Diagnosis TEXT NOT NULL,
    Note TEXT,
    FOREIGN KEY (VisitID) REFERENCES Core.Visit(VisitID),
    FOREIGN KEY (StaffID) REFERENCES Core.Staff(StaffID), 
    FOREIGN KEY (AnimalID) REFERENCES Core.Animal(AnimalID)
);

-- TABLE 12: Invoice (Finance)
CREATE TABLE Finance.Invoice (
    InvoiceID INT PRIMARY KEY,
    VisitID INT NOT NULL UNIQUE,
    TotalAmount DECIMAL(10,2) NOT NULL CHECK (TotalAmount >= 0),
    Discount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (Discount >= 0),
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'Pending' 
        CHECK (PaymentStatus IN ('Pending', 'Paid', 'Partial', 'Cancelled')),
    InvoiceDate DATE NOT NULL,
    FOREIGN KEY (VisitID) REFERENCES Core.Visit(VisitID),
    CONSTRAINT CHK_Discount_LessThan_Total 
        CHECK (Discount <= TotalAmount)
);

-- TABLE 13: VaccinationSchedule (Core)
CREATE TABLE Core.VaccinationSchedule (
    VaccinationID INT PRIMARY KEY,
    AnimalID INT NOT NULL,
    VaccineID INT NOT NULL,
    VaccinationName VARCHAR(100) NOT NULL,
    GivenDate DATE NOT NULL,
    NextDueDate DATE ,
    FOREIGN KEY (AnimalID) REFERENCES Core.Animal(AnimalID),
    FOREIGN KEY (VaccineID) REFERENCES Core.Vaccine(VaccineID),
    CONSTRAINT CHK_NextDate_After_Given 
        CHECK (NextDueDate > GivenDate)
);

-- TABLE 14: ServiceInvoiceDetail (Finance)
CREATE TABLE Finance.ServiceInvoiceDetail (
    InvoiceID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    CostPrice DECIMAL(10,2) NOT NULL CHECK (CostPrice >= 0),
    PRIMARY KEY (InvoiceID, ServiceID),
    FOREIGN KEY (InvoiceID) REFERENCES Finance.Invoice(InvoiceID),
    FOREIGN KEY (ServiceID) REFERENCES Core.Service(ServiceID) 
);

-- TABLE 15: MedicationInvoiceDetail (Finance)
CREATE TABLE Finance.MedicationInvoiceDetail (
    InvoiceID INT NOT NULL,
    MedicationID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    CostPrice DECIMAL(10,2) NOT NULL CHECK (CostPrice >= 0),
    PRIMARY KEY (InvoiceID, MedicationID),
    FOREIGN KEY (InvoiceID) REFERENCES Finance.Invoice(InvoiceID),
    FOREIGN KEY (MedicationID) REFERENCES Finance.Medication(MedicationID)
);
-- ===========================================
-- STEP 3: INSERT DATA 
-- ===========================================

-- 1. Species (5 records) - Core
INSERT INTO Core.Species (SpeciesID, SpeciesName) VALUES
(1, 'Dog'),
(2, 'Cat'),
(3, 'Bird'),
(4, 'Rabbit'),
(5, 'Hamster');

-- 2. Customer (5 records) - Core
INSERT INTO Core.Customer (CustomerID, FullName, PhoneNumber, Email, Address, Status) VALUES
(1001, 'Malak Zahda', '0551234567', 'malak011@gmail.com', 'Hebron-Al Harah Al Tahta', 'Active'),
(1002, 'Hala Zahda', '0507654321', 'hala0@email.com', 'Hebron-Ein Karim', 'Active'),
(1003, 'Ibrahim Zahda', '0568889999', 'ibrahim2@gmail.com', 'Bethlehem-Janata', 'Active'),
(1004, 'Radwan Abu snineh', '0541112222', 'radwan11@gmail.com', 'Bethlehem-Hindaza', 'Inactive'),
(1005, 'Yahya Masri', '0533334444', 'yahya1@gmail.com', 'Bethlehem-Hindaza', 'Active');

-- 3. Staff (5 records) - Core 
INSERT INTO Core.Staff (StaffID, FullName, Role, PhoneNumber, Email, Status) VALUES
(2001, 'Dr. Fahad Al-Qawasmi', 'Veterinarian', '0555551234', 'fahad@vetclinic.com', 'Active'),
(2002, 'Dr. Lama Al-Sharabati', 'Veterinarian', '0505556789', 'lama@vetclinic.com', 'Active'),
(2003, 'Ahmed Jabari', 'Assistant', '0565559012', 'ahmedj@vetclinic.com', 'Active'),
(2004, 'Nouf Salhab', 'Receptionist', '0545553456', 'nouf@vetclinic.com', 'Active'),
(2005, 'Dr. Saeed Almasri', 'Surgeon', '0535557890', 'saed@vetclinic.com', 'Active');

-- 4. Service (5 records) - Core 
INSERT INTO Core.Service (ServiceID, ServiceName, Price, CostPrice, Category) VALUES
(1, 'General Examination', 80.00, 30.00, 'Examination'),
(2, 'Vaccination', 120.00, 45.00, 'Vaccination'),
(3, 'Dental Cleaning', 200.00, 80.00, 'Dental'),
(4, 'X-Ray', 350.00, 150.00, 'Diagnostic'),
(5, 'Grooming', 100.00, 25.00, 'Grooming');

-- 5. Medication (5 records) - Finance
INSERT INTO Finance.Medication (MedicationID, Name, Price, CostPrice, Unit) VALUES
(1, 'Antibiotic A', 50.00, 15.00, 'Tablet'),
(2, 'Painkiller B', 30.00, 8.00, 'Tablet'),
(3, 'Antiparasitic C', 120.00, 40.00, 'Bottle'),
(4, 'Vitamins D', 80.00, 20.00, 'Bottle'),
(5, 'Antifungal E', 95.00, 30.00, 'Tube');

-- 6. Vaccine (5 records) - Core
INSERT INTO Core.Vaccine (VaccineID, VaccineName, Duration, Description) VALUES
(1, 'Rabies Vaccine', 36, 'Required by law for dogs and cats'),
(2, 'Feline Triple', 12, 'For cats against 3 common diseases'),
(3, 'Canine Parvovirus', 12, 'Essential for puppies'),
(4, 'Kennel Cough', 6, 'For dogs in boarding facilities'),
(5, 'Leukemia Vaccine', 12, 'For cats at risk');

-- 7. Breed (5 records) - Core
INSERT INTO Core.Breed (BreedID, BreedName, SpeciesID) VALUES
(1, 'German Shepherd', 1),
(2, 'Siamese', 2),
(3, 'Persian', 2),
(4, 'Parrot', 3),
(5, 'Holland Lop', 4);

-- 8. Animal (5 records) - Core
INSERT INTO Core.Animal (AnimalID, CustomerID, BreedID, Name, Gender, BirthDate, Status) VALUES
(1, 1001, 1, 'Rex', 'Male', '2020-03-15', 'Active'),
(2, 1002, 2, 'Luna', 'Female', '2021-01-10', 'Active'),
(3, 1001, 3, 'Max', 'Male', '2019-07-22', 'Active'),
(4, 1003, 4, 'Twitter', 'Male', '2022-05-05', 'Active'),
(5, 1005, 1, 'Black', 'Male', '2018-11-30', 'Active');

-- 9. Inventory (5 records) - Finance
INSERT INTO Finance.Inventory (InventoryID, MedicationID, Quantity, ExpiryDate) VALUES
(1, 1, 50, '2025-12-31'),
(2, 2, 100, '2024-06-30'),
(3, 3, 25, '2025-03-15'),
(4, 4, 75, '2024-09-30'),
(5, 5, 30, '2025-01-20');

-- 10. Visit (5 records) - Core
INSERT INTO Core.Visit (VisitID, CustomerID, Status, Note) VALUES
(101, 1001, 'Completed', 'Routine checkup for Rex'),
(102, 1002, 'Completed', 'Vaccination for Luna'),
(103, 1001, 'Scheduled', 'Follow-up for Max'),
(104, 1003, 'In Progress', 'Emergency visit for Twitter'),
(105, 1005, 'Completed', 'Annual vaccination');

-- 11. Examination (5 records) - Core
INSERT INTO Core.Examination (ExamID, VisitID, StaffID, AnimalID, Diagnosis, Note) VALUES
(1, 101, 2001, 1, 'Healthy', 'Normal vitals, good weight'),
(2, 102, 2002, 2, 'Vaccination needed', 'Due for annual shots'),
(3, 103, 2001, 3, 'Skin infection', 'Prescribed antibiotics'),
(4, 104, 2003, 4, 'Respiratory issue', 'Needs observation'),
(5, 105, 2002, 5, 'Healthy', 'All vaccinations up to date');

-- 12. Invoice (5 records) - Finance
INSERT INTO Finance.Invoice (InvoiceID, VisitID, TotalAmount, Discount, PaymentStatus, InvoiceDate) VALUES
(1001, 101, 150.00, 0, 'Paid', '2024-01-10'),
(1002, 102, 120.00, 10.00, 'Paid', '2024-01-12'),
(1003, 103, 95.50, 0, 'Pending', '2024-01-15'),
(1004, 104, 300.00, 25.00, 'Partial', '2024-01-18'),
(1005, 105, 180.00, 0, 'Paid', '2024-01-20');

-- 13. VaccinationSchedule (5 records) - Core
INSERT INTO Core.VaccinationSchedule (VaccinationID, AnimalID, VaccineID, VaccinationName, GivenDate, NextDueDate) VALUES
(1, 1, 1, 'Rabies Shot', '2023-06-15', '2026-06-15'),
(2, 2, 2, 'Feline Triple', '2023-11-20', '2024-11-20'),
(3, 1, 3, 'Parvovirus Vaccine', '2023-08-10', '2024-08-10'),
(4, 4, 1, 'Rabies Shot', '2023-12-05', '2026-12-05'),
(5, 5, 4, 'Kennel Cough', '2024-01-15', '2024-07-15');

-- 14. ServiceInvoiceDetail (5 records) - Finance
INSERT INTO Finance.ServiceInvoiceDetail (InvoiceID, ServiceID, Quantity, Price, CostPrice) VALUES
(1001, 1, 1, 80.00, 30.00),
(1001, 2, 1, 120.00, 45.00),
(1002, 2, 1, 120.00, 45.00),
(1003, 1, 1, 80.00, 30.00),
(1004, 4, 1, 350.00, 150.00);

-- 15. MedicationInvoiceDetail (5 records) - Finance
INSERT INTO Finance.MedicationInvoiceDetail (InvoiceID, MedicationID, Quantity, Price, CostPrice) VALUES
(1001, 1, 10, 50.00, 15.00),
(1003, 2, 20, 30.00, 8.00),
(1003, 1, 15, 50.00, 15.00),
(1004, 3, 1, 120.00, 40.00),
(1005, 4, 2, 80.00, 20.00);

--=============================================
-- STEP 4: UPDATE statements (3 statements)
-- ===========================================

UPDATE Core.Customer 
SET PhoneNumber = '0559998888' 
WHERE CustomerID = 1001;

UPDATE Core.Animal 
SET Status = 'In Treatment' 
WHERE AnimalID = 3;

UPDATE Finance.Invoice 
SET PaymentStatus = 'Paid', Discount = 15.00 
WHERE InvoiceID = 1003;

-- ===============================================
-- STEP 5: DELETE statements (3 SAFE statements)
-- ===========================================

-- Safe DELETE 1: Delete expired vaccination schedules (safe) - Core
DELETE FROM Core.VaccinationSchedule 
WHERE NextDueDate < '2024-01-01';

-- Safe DELETE 2: Delete animals with specific status (safe - no FK issues from this side) - Core
DELETE FROM Core.Animal 
WHERE Status = 'Deceased';

-- Safe DELETE 3: Delete inventory items that are expired (safe) - Finance
DELETE FROM Finance.Inventory 
WHERE ExpiryDate < CAST(GETDATE() AS DATE);
--===================some of examples

SELECT * FROM core.Customer

SELECT a.Name AS AnimalName ,b.BreedName,s.SpeciesName
FROM Core.Animal a
JOIN Core.Breed b ON a.BreedID = b.BreedID 
JOIN Core.Species s ON b.SpeciesID=s.SpeciesID


                                        
SELECT * 
FROM Core.Customer 
WHERE FullName like '% Zahda'


SELECT PRICE FROM CORE.Service 

SELECT TOP(2) Price
FROM Core.Service
ORDER BY Core.Service.Price DESC