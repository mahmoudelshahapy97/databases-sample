
CREATE DATABASE clinic6_db;
USE clinic6_db;

-- 1. Departments

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY AUTO_INCREMENT,
    DepartmentName VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    HeadOfDepartment INT,
    ContactNumber VARCHAR(15),
    Email VARCHAR(100)
);

-- 2. MedicalStaff

CREATE TABLE MedicalStaff (
    MedStaffID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Role VARCHAR(50),
    DepartmentID INT,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    HireDate DATE,
    Status ENUM('Active', 'OnLeave', 'Retired'),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

-- Add FK for HeadOfDepartment

ALTER TABLE Departments
ADD CONSTRAINT fk_head_of_department
FOREIGN KEY (HeadOfDepartment) REFERENCES MedicalStaff(MedStaffID);

-- 3. NonMedicalStaff

CREATE TABLE NonMedicalStaff (
    StaffID INT PRIMARY KEY AUTO_INCREMENT,
	FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Role VARCHAR(50),
    DepartmentID INT,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    HireDate DATE,
    Status ENUM('Active', 'On Leave'),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

-- 4. Patients

CREATE TABLE Patients (
    PatientID INT PRIMARY KEY AUTO_INCREMENT,
	FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Gender ENUM('Male', 'Female', 'Other'),
    DOB DATE,
    Phone VARCHAR(15) UNIQUE,
    Email VARCHAR(100),
    Address TEXT,
    BloodType VARCHAR(3),
    RegistrationDate DATE
);

-- 5. Appointments

CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT NOT NULL,
    MedStaffID INT NOT NULL,
    AppointmentDate DATE,
    AppointmentTime TIME,
    VisitType ENUM('Checkup', 'Follow-up', 'Urgency', 'Consultation'),
    Status ENUM('Scheduled', 'Completed', 'Cancelled', 'No-Show'),
    Notes TEXT,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (MedStaffID) REFERENCES MedicalStaff(MedStaffID)
    
);

-- 6. Prescriptions

CREATE TABLE Prescriptions (
    AppointmentID INT,
    MedicationName VARCHAR(50),
    StartDate DATE,
    EndDamedicalrecordste DATE,
    Dosage VARCHAR(50),
    Instructions TEXT,
    FOREIGN KEY (AppointmentID) REFERENCES  Appointments(AppointmentID)
);

-- 7. MedicalRecords

CREATE TABLE MedicalRecords (
    PatientID INT NOT NULL ,
    MedStaffID INT NOT NULL,
    LastVisitDate DATE,
    Diagnosis TEXT,
    NextVisit DATE,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (MedStaffID) REFERENCES MedicalStaff(MedStaffID)
);


-- 8. Billing

CREATE TABLE Billing (
    BillID INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID INT,
    Amount DECIMAL(10, 2),
    PaymentMethod ENUM('Cash', 'CreditCard', 'Insurance'),
    Status ENUM('Paid', 'Pending'),
    DateIssued DATE,
    DatePaid DATE,
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
);

-- 9. LabTests

CREATE TABLE LabReferrals (
    LabReferralID INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID INT,
    TestType VARCHAR(100),
    TestDate DATE,
    Result TEXT,
    Status ENUM('Ordered', 'Completed'),
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
);

-- 10. Allergies

CREATE TABLE Allergies (
PatientID INT,
Allergies VARCHAR(100),
FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);

-- DATA INSERTS 

-- Insert Departments records
INSERT INTO Departments (DepartmentID, DepartmentName, Description, ContactNumber, Email) VALUES
(1, 'Cardiology', 'Heart-related medical care', '4167321947', 'cardiology@clinic6sql.com'),
(2, 'Neurology', 'Nervous system disorders treatment', '6478293048', 'neurology@clinic6sql.com'),
(3, 'Pediatrics', 'Healthcare for children', '9056132875', 'pediatrics@clinic6sql.com');

-- Insert Medical Staff records
INSERT INTO MedicalStaff (MedStaffID, FirstName, LastName, Role, DepartmentID, Phone, Email, HireDate, Status) VALUES
(1, 'John', 'Doe', 'Cardiologist', 1, '4169273641', 'jdoe@clinic6sql.com', '2015-06-10', 'Active'),
(2, 'Alice', 'Smith', 'Neurologist', 2, '6474185297', 'asmith@clinic6sql.com', '2018-09-23', 'Active'),
(3, 'Robert', 'Brown', 'Pediatrician', 3, '9057364829', 'rbrown@clinic6sql.com', '2020-03-15', 'Active');

-- Assign Head of Department
UPDATE Departments SET HeadOfDepartment = 1 WHERE DepartmentID = 1;
UPDATE Departments SET HeadOfDepartment = 2 WHERE DepartmentID = 2;
UPDATE Departments SET HeadOfDepartment = 3 WHERE DepartmentID = 3;

-- Insert Non-Medical Staff records
INSERT INTO NonMedicalStaff (StaffID, FirstName, LastName, Role, DepartmentID, Phone, Email, HireDate, Status) VALUES
(1, 'Sarah', 'White', 'Receptionist', 1, '4165348792', 'swhite@clinic6sql.com', '2021-01-15', 'Active'),
(2, 'James', 'Green', 'Billing Specialist', 2, '6472957483', 'jgreen@clinic6sql.com', '2019-07-22', 'Active'),
(3, 'Linda', 'Black', 'Administrator', 3, '9054186729', 'lblack@clinic6sql.com', '2017-11-05', 'Active');

-- Insert Patients records
INSERT INTO Patients (PatientID, FirstName, LastName, Gender, DOB, Phone, Email, Address, BloodType, RegistrationDate) VALUES
(1, 'Michael', 'Johnson', 'Male', '1980-05-12', '4166372948', 'michael.johnson@gmail.com', '123 Elm St, City', 'O+', '2024-01-10'),
(2, 'Jessica', 'Davis', 'Female', '1992-08-25', '6478294756', 'jessica.davis@outlook.com', '456 Oak St, City', 'A-', '2024-01-12'),
(3, 'Emily', 'Martinez', 'Female', '2001-03-15', '9057263984', 'emartinez@icloud.com', '789 Pine St, City', 'B+', '2024-01-14'),
(4, 'William', 'Anderson', 'Male', '1985-07-10', '4164829357', 'wanderson@yahoo.com', '321 Maple St, City', 'AB-', '2024-01-16'),
(5, 'Daniel', 'Thomas', 'Male', '1978-11-05', '6479283647', 'daniel.thomas@gmail.com', '654 Cedar St, City', 'O-', '2024-01-18'),
(6, 'Sophia', 'Miller', 'Female', '1995-06-20', '9056728492', 'sophia.miller@gmail.com', '147 Birch St, City', 'A+', '2024-01-20'),
(7, 'Benjamin', 'Garcia', 'Male', '1982-12-14', '4168392647', 'benjamin.garcia@outlook.com', '963 Walnut St, City', 'B-', '2024-01-22'),
(8, 'Olivia', 'Rodriguez', 'Female', '1999-09-30', '6475269384', 'olivia.rodriguez@icloud.com', '852 Spruce St, City', 'AB+', '2024-01-24'),
(9, 'Ethan', 'Harris', 'Male', '1974-04-05', '9053762958', 'ethan.harris@yahoo.com', '369 Aspen St, City', 'O-', '2024-01-26'),
(10, 'Ava', 'Clark', 'Female', '1988-07-19', '4165928473', 'ava.clark@gmail.com', '258 Redwood St, City', 'A-', '2024-01-28'),
(11, 'Mason', 'Lewis', 'Male', '2003-02-27', '6478392056', 'mason.lewis@outlook.com', '753 Fir St, City', 'B+', '2024-01-30'),
(12, 'Isabella', 'Walker', 'Female', '1977-11-12', '9056472839', 'isabella.walker@icloud.com', '159 Cedar St, City', 'AB-', '2024-02-01'),
(13, 'Lucas', 'Young', 'Male', '1993-08-08', '4167384926', 'lucas.young@yahoo.com', '624 Hickory St, City', 'O+', '2024-02-03'),
(14, 'Mia', 'King', 'Female', '1981-03-09', '6471928364', 'mia.king@gmail.com', '753 Elm St, City', 'A+', '2024-02-05'),
(15, 'Alexander', 'Scott', 'Male', '1996-06-25', '9058293746', 'alexander.scott@outlook.com', '147 Oak St, City', 'B-', '2024-02-07'),
(16, 'Charlotte', 'Hall', 'Female', '2000-10-18', '4169872536', 'charlotte.hall@icloud.com', '258 Pine St, City', 'AB+', '2024-02-09'),
(17, 'Elijah', 'Allen', 'Male', '1989-09-01', '6472938472', 'elijah.allen@yahoo.com', '369 Maple St, City', 'O-', '2024-02-11'),
(18, 'Amelia', 'Wright', 'Female', '1975-05-07', '9057632849', 'amelia.wright@gmail.com', '753 Spruce St, City', 'A-', '2024-02-13'),
(19, 'James', 'Lopez', 'Male', '1991-12-23', '4162839475', 'james.lopez@outlook.com', '159 Redwood St, City', 'B+', '2024-02-15'),
(20, 'Harper', 'Hill', 'Female', '1986-07-14', '6479283754', 'harper.hill@icloud.com', '624 Fir St, City', 'AB-', '2024-02-17');

-- Insert appointments records 
INSERT INTO Appointments (AppointmentID, PatientID, MedStaffID, AppointmentDate, AppointmentTime, VisitType, Status, Notes) VALUES
(1, 1, 1, '2024-03-01', '09:00:00', 'Checkup', 'Completed', 'Routine heart checkup, no major concerns.'),
(2, 2, 2, '2024-03-02', '10:30:00', 'Consultation', 'Completed', 'Discussed migraine management plan.'),
(3, 3, 3, '2024-03-03', '11:00:00', 'Checkup', 'Completed', 'Child received routine vaccination.'),
(4, 4, 1, '2024-03-04', '14:00:00', 'Urgency', 'Completed', 'Patient reported chest pain, no serious findings.'),
(5, 5, 2, '2024-03-05', '15:30:00', 'Consultation', 'Completed', 'Assessment for recent seizure episode.'),
(6, 6, 3, '2024-03-06', '08:45:00', 'Checkup', 'Scheduled', 'Routine child vaccination.'),
(7, 7, 1, '2024-03-07', '09:15:00', 'Follow-up', 'Scheduled', 'Monitoring hypertension progress.'),
(8, 8, 2, '2024-03-08', '10:00:00', 'Consultation', 'Scheduled', 'Evaluating chronic headaches.'),
(9, 9, 3, '2024-03-09', '13:00:00', 'Checkup', 'Cancelled', 'Patient rescheduled appointment.'),
(10, 10, 1, '2024-03-10', '14:30:00', 'Urgency', 'Completed', 'Heart palpitations reported, prescribed medication.'),
(11, 11, 2, '2024-03-11', '15:00:00', 'Consultation', 'No-Show', 'Patient did not attend.'),
(12, 12, 3, '2024-03-12', '09:30:00', 'Urgency', 'Completed', 'Flu-like symptoms, advised rest and hydration.'),
(13, 13, 1, '2024-03-13', '10:45:00', 'Follow-up', 'Scheduled', 'Post-heart surgery monitoring.'),
(14, 14, 2, '2024-03-14', '12:15:00', 'Consultation', 'Scheduled', 'Assessing numbness in fingers.'),
(15, 15, 3, '2024-03-15', '14:00:00', 'Checkup', 'Scheduled', 'Fever and sore throat, possible strep infection.'),
(16, 16, 1, '2024-03-16', '09:00:00', 'Checkup', 'Scheduled', 'Routine blood pressure check.'),
(17, 17, 2, '2024-03-17', '11:30:00', 'Follow-up', 'Completed', 'Seizure management discussion.'),
(18, 18, 3, '2024-03-18', '13:45:00', 'Consultation', 'Completed', 'Discussing childhood asthma symptoms.'),
(19, 19, 1, '2024-03-19', '15:30:00', 'Urgency', 'Completed', 'Heartburn and chest discomfort assessment.'),
(20, 20, 2, '2024-03-20', '10:00:00', 'Follow-up', 'Scheduled', 'Reviewing migraine treatment effectiveness.');



-- Insert Prescriptions
INSERT INTO Prescriptions (AppointmentID, MedicationName, StartDate, EndDate, Dosage, Instructions) VALUES
(1, 'Aspirin', '2024-03-05', '2024-03-15', '100mg', 'Take one daily after meals'),
(2, 'Ibuprofen', '2024-03-06', '2024-03-10', '200mg', 'Take one every 6 hours as needed'),
(3, 'Amoxicillin', '2024-03-07', '2024-03-14', '500mg', 'Take one every 8 hours for infection'),
(5, 'Metoprolol', '2024-03-10', '2024-03-20', '50mg', 'Take one daily'),
(10, 'Paracetamol', '2024-03-12', '2024-03-14', '500mg', 'Take every 6 hours as needed'),
(12, 'Lisinopril', '2024-03-13', '2024-03-30', '10mg', 'Take one daily in the morning'),
(17, 'Ventolin Inhaler', '2024-03-14', '2024-04-14', 'As needed', 'Use during asthma attacks'),
(18, 'Ibuprofen', '2024-03-16', '2024-03-18', '400mg', 'Take every 8 hours with food'),
(19, 'Prednisone', '2024-03-18', '2024-03-25', '20mg', 'Take one daily for a week'),
(19, 'Amoxicillin', '2024-03-19', '2024-03-26', '500mg', 'Take one every 8 hours');

-- Insert Medical Records
INSERT INTO MedicalRecords (PatientID, MedStaffID, LastVisitDate, Diagnosis, NextVisit) VALUES
(1, 2, '2024-03-05', 'Mild Epilepsy', '2024-06-05'),
(1, 1, '2024-03-25', 'High Cholesterol', '2024-09-25'),
(2, 3, '2024-03-06', 'Childhood Migraines', '2024-06-06'),
(2, 2, '2024-03-26', 'Sleep Apnea', '2024-06-26'),
(3, 1, '2024-03-07', 'Minor Heart Murmur', '2024-07-07'),
(3, 3, '2024-03-27', 'Bronchitis', NULL),
(4, 2, '2024-03-08', 'Cluster Headaches', '2024-06-08'),
(4, 1, '2024-03-28', 'Mild Hypertension', '2024-07-28'),
(5, 3, '2024-03-09', 'Common Cold', NULL),
(5, 2, '2024-03-29', 'Epileptic Episodes', '2024-06-29'),
(6, 1, '2024-03-10', 'Hypertension', '2024-06-10'),
(6, 3, '2024-03-30', 'Childhood Obesity', '2024-09-30'),
(7, 2, '2024-03-11', 'Vertigo', '2024-06-11'),
(7, 1, '2024-03-31', 'Heart Palpitations', '2024-07-31'),
(8, 3, '2024-03-12', 'Allergic Rhinitis', '2024-09-12'),
(8, 2, '2024-03-14', 'Tension Headaches', '2024-06-14'),
(9, 1, '2024-03-13', 'Post-Operative Recovery', '2024-06-13'),
(9, 2, '2024-03-17', 'Seizure Disorder', '2024-09-17'),
(10, 3, '2024-03-15', 'Flu', NULL),
(10, 1, '2024-03-19', 'Heartburn', NULL),
(11, 2, '2024-03-16', 'Migraine with Aura', '2024-06-20'),
(11, 3, '2024-03-18', 'Asthma', '2024-06-18'),
(12, 1, '2024-03-22', 'Coronary Artery Disease', '2024-07-22'),
(12, 2, '2024-03-23', 'Parkinson’s Disease', '2024-09-23'),
(13, 3, '2024-03-24', 'Childhood Asthma', '2024-06-24'),
(13, 2, '2024-03-29', 'Chronic Fatigue Syndrome', '2024-09-29');

-- Insert Lab Referrals 
INSERT INTO LabReferrals (LabReferralID, AppointmentID, TestType, TestDate, Result, Status) VALUES
(1, 1, 'Blood Test', '2024-03-05', 'Normal', 'Completed'),
(2, 2, 'MRI', '2024-03-06', 'No abnormalities detected', 'Completed'),
(3, 3, 'X-ray', '2024-03-07', NULL, 'Ordered'),
(4, 4, 'Echocardiogram', '2024-03-08', 'Mild valve regurgitation', 'Completed'),
(5, 5, 'CT Scan', '2024-03-09', NULL, 'Ordered'),
(6, 7, 'EEG', '2024-03-11', 'Mild irregular activity', 'Completed'),
(7, 9, 'Blood Panel', '2024-03-13', NULL, 'Ordered'),
(8, 11, 'Ultrasound', '2024-03-15', 'Normal structure', 'Completed'),
(9, 13, 'Allergy Test', '2024-03-17', NULL, 'Ordered'),
(10, 15, 'Lipid Profile', '2024-03-19', 'High cholesterol detected', 'Completed');

-- Insert Billing records
INSERT INTO Billing (BillID, AppointmentID, Amount, PaymentMethod, Status, DateIssued, DatePaid) VALUES
(1, 1, 200.00, 'CreditCard', 'Paid', '2024-03-01', '2024-03-01'),
(2, 2, 150.00, 'Insurance', 'Paid', '2024-03-02', '2024-03-03'),
(3, 3, 75.00, 'Cash', 'Pending', '2024-03-03', NULL),
(4, 4, 300.00, 'CreditCard', 'Paid', '2024-03-04', '2024-03-04'),
(5, 5, 500.00, 'Insurance', 'Pending', '2024-03-05', NULL),
(6, 6, 220.00, 'Cash', 'Paid', '2024-03-06', '2024-03-06'),
(7, 7, 180.00, 'CreditCard', 'Paid', '2024-03-07', '2024-03-07'),
(8, 8, 250.00, 'Insurance', 'Pending', '2024-03-08', NULL),
(9, 9, 90.00, 'Cash', 'Paid', '2024-03-09', '2024-03-09'),
(10, 10, 275.00, 'CreditCard', 'Pending', '2024-03-10', NULL),
(11, 11, 130.00, 'Insurance', 'Paid', '2024-03-11', '2024-03-12'),
(12, 12, 160.00, 'Cash', 'Paid', '2024-03-12', '2024-03-12'),
(13, 13, 120.00, 'CreditCard', 'Pending', '2024-03-13', NULL),
(14, 14, 240.00, 'Insurance', 'Paid', '2024-03-14', '2024-03-14'),
(15, 15, 350.00, 'Cash', 'Paid', '2024-03-15', '2024-03-15'),
(16, 16, 400.00, 'CreditCard', 'Pending', '2024-03-16', NULL),
(17, 17, 210.00, 'Insurance', 'Paid', '2024-03-17', '2024-03-17'),
(18, 18, 110.00, 'Cash', 'Paid', '2024-03-18', '2024-03-18'),
(19, 19, 310.00, 'CreditCard', 'Pending', '2024-03-19', NULL),
(20, 20, 270.00, 'Insurance', 'Paid', '2024-03-20', '2024-03-20');

-- Insert Allergies record 
INSERT INTO Allergies (PatientID, Allergies) VALUES
(1, 'Peanuts'),
(1, 'Shellfish'),
(2, 'Penicillin'),
(4, 'Pollen'),
(4, 'Dust'),
(5, 'Latex'),
(7, 'Dairy'),
(7, 'Eggs'),
(8, 'Bee Stings'),
(10, 'Gluten'),
(11, 'Peanuts'),
(11, 'Soy'),
(11, 'Wheat'),
(12, 'Shellfish'),
(12, 'Strawberries'),
(14, 'Mold'),
(15, 'Tree Nuts'),
(17, 'Dander'),
(17, 'Perfume'),
(18, 'Grass Pollen'),
(20, 'Penicillin'),
(20, 'Sulfa Drugs');

-- UPDATE STATEMENTS AFTER CSV IMPORTS

UPDATE departments
SET HeadOfDepartment = 4 
WHERE DepartmentID = 4;

UPDATE departments
SET HeadOfDepartment = 7 
WHERE DepartmentID = 5;

UPDATE departments
SET HeadOfDepartment = 12 
WHERE DepartmentID = 6;

UPDATE departments
SET HeadOfDepartment = 17 
WHERE DepartmentID = 7;

UPDATE departments
SET HeadOfDepartment = 22 
WHERE DepartmentID = 8;

UPDATE departments
SET HeadOfDepartment = 25 
WHERE DepartmentID = 9;

UPDATE departments
SET HeadOfDepartment = 28 
WHERE DepartmentID = 10;

UPDATE departments
SET HeadOfDepartment = 33 
WHERE DepartmentID = 12;
