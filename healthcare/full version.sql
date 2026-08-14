CREATE DATABASE ClinicDB;
USE ClinicDB;
CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
CREATE TABLE Clinic (
    clinic_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);
CREATE TABLE Doctor (
    doctor_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);
CREATE TABLE Patient (
    patient_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    birth_date DATE,
    job VARCHAR(100)
);
CREATE TABLE Appointment (
    appointment_id INT PRIMARY KEY,
    appointment_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    cost DECIMAL(10,2),
    status ENUM('scheduled', 'in progress', 'postponed') DEFAULT 'scheduled',
    diagnosis TEXT,

    patient_id INT,
    doctor_id INT,

    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctor(doctor_id)
);
ALTER TABLE Appointment
ADD clinic_id INT,
ADD FOREIGN KEY (clinic_id) REFERENCES Clinic(clinic_id);





USE ClinicDB;
INSERT INTO Department (dept_id, name) VALUES
(1,'Cardiology'), (2,'Gastroenterology'), (3,'Dermatology'), (4,'Neurology'),
(5,'Orthopedics'), (6,'Pediatrics'), (7,'Oncology'), (8,'ENT'),
(9,'Ophthalmology'), (10,'Urology'), (11,'Psychiatry'), (12,'Endocrinology'),
(13,'Nephrology'), (14,'Pulmonology'), (15,'Rheumatology'),
(16,'Hematology'), (17,'Immunology'), (18,'General Surgery'),
(19,'Plastic Surgery'), (20,'Emergency');

INSERT INTO Clinic (clinic_id, name, address, dept_id) VALUES
(101,'Heart Care Clinic','Cairo - Nasr City',1),
(102,'Cardio Plus','Giza - Dokki',1),
(103,'Digestive Clinic','Cairo - Maadi',2),
(104,'Skin Care','Cairo - Heliopolis',3),
(105,'Brain Clinic','Giza - Mohandessin',4),
(106,'Bone Clinic','Cairo - 6th October',5),
(107,'Kids Care','Giza - Haram',6),
(108,'Cancer Center','Cairo - Abbasiya',7),
(109,'ENT Care','Cairo - Zamalek',8),
(110,'Eye Center','Giza - Sheikh Zayed',9),
(111,'Urology Care','Cairo - Nasr City',10),
(112,'Mental Health','Cairo - Maadi',11),
(113,'Diabetes Clinic','Giza - Dokki',12),
(114,'Kidney Care','Cairo - Heliopolis',13),
(115,'Chest Clinic','Cairo - Shubra',14),
(116,'Joint Clinic','Giza - Faisal',15),
(117,'Blood Clinic','Cairo - Abbasiya',16),
(118,'Immunity Center','Giza - Mohandessin',17),
(119,'Surgery Center','Cairo - Nasr City',18),
(120,'Emergency Unit','Giza - Dokki',20);


INSERT INTO Doctor (doctor_id, name, phone, address, dept_id)
SELECT 
    1000 + n,
    CONCAT('Dr. Doctor_', n),
    CONCAT('010', FLOOR(10000000 + RAND()*89999999)),
    'Cairo',
    FLOOR(1 + RAND()*20)
FROM (
    SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
) t;


INSERT INTO Patient (patient_id, name, phone, address, birth_date, job)
SELECT 
    12500 + n,
    CONCAT('Patient_', n),
    CONCAT('010', FLOOR(10000000 + RAND()*89999999)),
    'Giza',
    DATE_SUB(CURDATE(), INTERVAL FLOOR(18 + RAND()*40) YEAR),
    ELT(FLOOR(1 + RAND()*5), 'Student','Engineer','Doctor','Teacher','Designer')
FROM (
    SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
) t;



ALTER TABLE Appointment 
MODIFY status ENUM('scheduled','in progress','postponed','completed');



INSERT INTO Appointment 
(appointment_id, appointment_date, start_time, end_time, cost, status, diagnosis, patient_id, doctor_id)
SELECT
    n,
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*1000) DAY),
    MAKETIME(FLOOR(8 + RAND()*8), 0, 0),
    MAKETIME(FLOOR(9 + RAND()*8), 30, 0),
    ROUND(200 + RAND()*800, 2),
    ELT(FLOOR(1 + RAND()*4), 'scheduled','in progress','postponed','completed'),
    ELT(FLOOR(1 + RAND()*5), 'fatty liver','diabetes','migraine','heart disease','checkup'),
    12500 + FLOOR(1 + RAND()*20),
    1000 + FLOOR(1 + RAND()*20)
FROM (
    SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
) t;