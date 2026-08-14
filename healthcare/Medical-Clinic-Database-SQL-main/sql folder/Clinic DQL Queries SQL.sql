USE clinic6_db;


-- Query 1 patients visit summary
SELECT 
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS Full_Name,
    COUNT(a.AppointmentID) AS Total_Appointments,
    SUM(CASE 
			WHEN a.Status = 'No-Show' 
			THEN 1 ELSE 0 
        END) AS Missed_Appointments,
    MIN(a.AppointmentDate) AS First_Visit,
    MAX(a.AppointmentDate) AS Last_Visit
FROM Patients p
LEFT JOIN Appointments a ON p.PatientID = a.PatientID
GROUP BY p.PatientID
ORDER BY Total_appointments DESC;

-- Query 2 Billing per patient details
SELECT 
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS Full_Name,
    COUNT(b.BillID) AS Total_Bills,
    SUM(b.Amount) AS Total_Amount,
    AVG(b.Amount) AS Avg_Bill,
    SUM(CASE WHEN b.Status = 'Unpaid' THEN b.Amount ELSE 0 END) AS Total_Unpaid
FROM Patients p
LEFT JOIN appointments a ON p.PatientID = a.PatientID
LEFT JOIN billing b ON a.AppointmentID = b.AppointmentID
GROUP BY p.PatientID
ORDER BY Total_Amount DESC;

-- Query 3 prescriptions history per patient, it allows for more in depth anakysis with a where clause
SELECT  
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS Full_Name,
    pr.MedicationName AS Medication_Name,
    COUNT(DISTINCT pr.AppointmentID) AS Total_Prescriptions,
    MIN(pr.StartDate) AS First_Use,
    MAX(pr.EndDate) AS Last_Use
FROM Patients p
LEFT JOIN Appointments a ON p.PatientID = a.PatientID
LEFT JOIN Prescriptions pr ON a.AppointmentID = pr.AppointmentID
GROUP BY p.PatientID, pr.MedicationName
ORDER BY Total_Prescriptions DESC;

-- Query 4 Lab tests summary per patient
SELECT 
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS Full_Name,
    COUNT(lr.LabReferralID) AS Total_Tests_Ordered,
	COUNT(CASE WHEN lr.Status = 'Completed' THEN 1 END) AS Tests_Completed,
    COUNT(CASE WHEN lr.Status = 'Ordered' THEN 1 END) AS Tests_Pending,
    MAX(lr.TestDate) AS Most_Recent_Test_Date
FROM Patients p
LEFT JOIN appointments a ON p.PatientID = a.PatientID
LEFT JOIN labreferrals lr ON a.AppointmentID = lr.AppointmentID
GROUP BY p.PatientID
ORDER BY Total_Tests_Ordered DESC;

-- Query 5 Total Appointments in a Year compared to AVG appointments in a year for all providers
SELECT 
    a.MedStaffID,
    CONCAT(m.FirstName, ' ', m.LastName) AS Med_Staff_Name,
    COUNT(a.AppointmentID) AS Total_Appointments,
    AVG(COUNT(a.AppointmentID)) OVER () AS Avg_Appointments_All_Providers
FROM Appointments a
JOIN MedicalStaff m ON a.MedStaffID = m.MedStaffID
GROUP BY a.MedStaffID, Med_Staff_Name
ORDER BY Total_Appointments DESC;


-- Query 6 appointment trends to analyze peak months
SELECT 
    MONTH(AppointmentDate) AS Month,
    COUNT(*) AS Appointment_Count,
    SUM(CASE WHEN Status = 'No-Show' THEN 1 ELSE 0 END) AS No_Show_Count
FROM Appointments
GROUP BY MONTH(AppointmentDate)
ORDER BY Month;

-- Query 7 frequently prescribed medication for forecasting drug demand
SELECT 
    MedicationName AS Medication_Name,
    COUNT(*) AS Times_Prescribed
FROM Prescriptions pr
GROUP BY MedicationName
ORDER BY Times_Prescribed DESC;

-- Query 8 Patients with above-average billing amount
CREATE VIEW PatientBilling AS (
    SELECT 
        p.PatientID,
        SUM(b.Amount) AS TotalBilled
    FROM patients p 
    JOIN appointments a ON p.PatientID=a.PatientID
    JOIN billing b ON a.AppointmentID=b.AppointmentID
    GROUP BY PatientID
);

WITH AverageBilling AS (
    SELECT 
		AVG(TotalBilled) AS AvgBilled
    FROM PatientBilling
)
SELECT 
    pb.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS Full_Name,
    pb.TotalBilled AS Total_Billed,
    ROUND(AvgBilled,2) AS Average_Billed
FROM PatientBilling pb
JOIN Patients p ON pb.PatientID = p.PatientID
JOIN AverageBilling ab
WHERE pb.TotalBilled > ab.AvgBilled
ORDER BY PatientID;


