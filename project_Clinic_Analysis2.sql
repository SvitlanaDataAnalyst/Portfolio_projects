-- Running the database. Reviewing the tables 
-- Lancement de la base de données. Visualisation des tables  

USE mis602_ass2;
show tables;
describe appointment;
SELECT * FROM appointment order by appointment_date;
SELECT * FROM doctor;
SELECT * FROM medication;
SELECT * FROM patient;
SELECT * FROM prescription;
SELECT * FROM speciality;

-- Data Cleaning  
-- Nettoyage des données  

select trim(name)
FROM patient;

SELECT name ,
CASE
WHEN trim(name) = 'AnnaLee' THEN 'Anna Lee'
When trim(name) = 'PortiaLee' THEN 'Portia Lee'
When trim(name) = 'SarahLee' THEN 'Sarah Lee'
ELSE trim(name)
END as corr_name
FROM patient;

-- Calculating the age of each patient on the current date  
-- Calcul de l'âge de chaque patient à la date actuelle  

select name, dob, timestampdiff(year, dob, now()) as age  FROM patient
order by name;
 
-- Calculating the age of the oldest patient, the youngest patient, the average age of the patients, and the total number of patients  
-- Calcul de l'âge du patient le plus âgé, du plus jeune, de l'âge moyen des patients et du nombre total de patients  
 
 SELECT max(timestampdiff(year, dob, now())) as max_age, min(timestampdiff(year, dob, now())) as min_age,
avg((timestampdiff(year, dob, now()))) as avg_age, count(patient_id) as count_of_patients
FROM patient;
 
-- Age analytics (18–35, 36–50, 50+)  
-- Analyse par tranche d’âge (18–35, 36–50, 50+)  
 
 SELECT 
trim(name) as name, dob, 
timestampdiff(year, dob, now()) as age,
 CASE
 WHEN timestampdiff(year, dob, now()) < 18 THEN 'Less than 18 years old'
 WHEN timestampdiff(year, dob, now()) BETWEEN 18 and 35 THEN '18-35 years old'
 WHEN timestampdiff(year, dob, now()) between 36 and 50 THEN '36-50 years old'
ELSE '50+ years old'
END as age_range
 from patient
 ORDER BY age_range;
  
 
-- Display a table with the appointment date, patient info, attending doctor, and prescription status  
-- Affichage d’un tableau avec la date du rendez-vous, les informations sur le patient, le médecin traitant et le statut des ordonnances  
 
 select distinct appointment.appointment_id, appointment.appointment_date, trim(patient.name) as patient_name, patient.dob,
 timestampdiff(year, patient.dob, now()) as age, patient.gender, doctor.name as doctor_name, speciality.name as speciality,
 CASE 
 WHEN prescription.medication_id IS NOT NULL THEN 'YES'
 ELSE 'NO'
 END as prescr_yes_or_no
     from appointment
LEFT JOIN patient
On appointment.patient_id=patient.patient_id
LEFT JOIN doctor
on appointment.doctor_id = doctor.doctor_id
Left join speciality
on speciality.speciality_id = doctor.speciality_id
Left join prescription
ON prescription.appointment_id = appointment.appointment_id 
Order by appointment.appointment_date
;

-- Remove duplicate visits from the resulting table  
-- Suppression des doublons de visites dans le tableau obtenu  

WITH ranked_appointments AS (
 select distinct appointment.appointment_id, appointment.appointment_date, trim(patient.name) as patient_name, patient.dob,
 timestampdiff(year, patient.dob, now()) as age, patient.gender, doctor.name as doctor_name, speciality.name as speciality,
 CASE 
 WHEN prescription.medication_id IS NOT NULL THEN 'YES'
 ELSE 'NO'
 END as prescr_yes_or_no,
 ROW_NUMBER() OVER (
      PARTITION BY patient.name, appointment.appointment_date
      ORDER BY 
        CASE WHEN prescr_yes_or_no = 'YES' THEN 1 ELSE 2 END
    ) AS rn
     from appointment
LEFT JOIN patient
On appointment.patient_id=patient.patient_id
LEFT JOIN doctor
on appointment.doctor_id = doctor.doctor_id
Left join speciality
on speciality.speciality_id = doctor.speciality_id
Left join prescription
ON prescription.appointment_id = appointment.appointment_id 
Order by appointment.appointment_date
)
SELECT *
FROM ranked_appointments
WHERE rn = 1;

-- View a patient-specific prescription  
-- Affichage de l’ordonnance d’un patient spécifique  

 select appointment.appointment_date, trim(patient.name) as patient_name, patient.dob,
 timestampdiff(year, patient.dob, now()) as age, patient.gender, doctor.name as doctor_name, speciality.name as speciality,
 medication.name as _medication, medication.dosage_form as _dosage_form, medication.strength as medication_strength, 
 medication.description as descr_of_medic
     from appointment
LEFT JOIN patient
On appointment.patient_id=patient.patient_id
LEFT JOIN doctor
on appointment.doctor_id = doctor.doctor_id
Left join speciality
on speciality.speciality_id = doctor.speciality_id
Left join prescription
ON prescription.appointment_id = appointment.appointment_id 
Left join medication
on prescription.medication_id = medication.medication_id
WHERE patient.name Like '%John%'
AND medication.name IS NOT NULL
AND medication.dosage_form IS NOT NULL
AND medication.strength IS NOT NULL
AND medication.description IS NOT NULL
Order by appointment.appointment_date;

-- Patients without any prescribed medications  
-- Patients sans médicaments prescrits  

select appointment.appointment_id, appointment.appointment_date, patient.name as patient_name,  patient.dob,
 timestampdiff(year, patient.dob, now()) as age, patient.gender, doctor.name as doctor_name, speciality.name as speciality,
 medication.name as _medication, medication.dosage_form as _dosage_form, medication.strength as medication_strength, 
 medication.description as descr_of_medic
     from appointment
LEFT JOIN patient
On appointment.patient_id=patient.patient_id
LEFT JOIN doctor
on appointment.doctor_id = doctor.doctor_id
Left join speciality
on speciality.speciality_id = doctor.speciality_id
Left join prescription
ON prescription.appointment_id = appointment.appointment_id 
Left join medication
on prescription.medication_id = medication.medication_id
AND medication.name IS NULL
AND medication.dosage_form IS NULL
AND medication.strength IS NULL
AND medication.description IS NULL
Order by appointment.appointment_date;

-- Number of patients without prescriptions  
-- Nombre de patients sans ordonnance  

SELECT COUNT(*) FROM patient;
SELECT COUNT(DISTINCT patient.patient_id) AS patients_with_no_prescr
FROM patient
LEFT JOIN appointment ON appointment.patient_id = patient.patient_id
LEFT JOIN prescription ON prescription.appointment_id = appointment.appointment_id
LEFT JOIN medication ON prescription.medication_id = medication.medication_id
WHERE medication.medication_id IS NULL;

-- General statistics: total patients, with and without prescriptions  
-- Statistiques générales : nombre total de patients, avec ou sans ordonnance

SELECT
    COUNT(DISTINCT patient.patient_id) AS total_patients,
    COUNT(DISTINCT CASE WHEN medication.medication_id IS NULL THEN patient.patient_id END) AS patients_without_prescriptions,
    COUNT(DISTINCT CASE WHEN medication.medication_id IS NOT NULL THEN patient.patient_id END) AS patients_with_prescriptions
FROM patient
LEFT JOIN appointment ON appointment.patient_id = patient.patient_id
LEFT JOIN prescription ON prescription.appointment_id = appointment.appointment_id
LEFT JOIN medication ON prescription.medication_id = medication.medication_id;

-- List of patients without any prescriptions  
-- Liste des patients sans ordonnance

SELECT patient.patient_id, patient.name
FROM patient
WHERE patient.patient_id NOT IN (
    SELECT DISTINCT appointment.patient_id
    FROM appointment
    JOIN prescription ON prescription.appointment_id = appointment.appointment_id
);

-- A table showing when the patient saw a doctor and how many times  
-- Tableau indiquant les dates de consultation du patient et le nombre de visites  

select appointment.appointment_id, appointment.patient_id, patient.patient_id, patient.name, 
row_number () OVER (Partition by patient.name) as row_num, 
count(appointment.patient_id) OVER (Partition by patient.name) as app_patient_count FROM appointment
join patient
ON appointment.patient_id = patient.patient_id
order by patient.name;


-- Number of appointments with each doctor  
-- Nombre de rendez-vous par médecin  

select appointment.appointment_id, appointment.patient_id, doctor.doctor_id, doctor.name, 
row_number () OVER (Partition by doctor.name) as row_num, 
count(appointment.doctor_id) OVER (Partition by doctor.name) as app_doct_count FROM appointment
join doctor
ON appointment.doctor_id = doctor.doctor_id
order by doctor.name;
 
-- A table with doctors who wrote the most prescriptions  
-- Tableau des médecins ayant rédigé le plus grand nombre d’ordonnances  

 WITH doc_prescr_count AS (
  SELECT
    doctor.doctor_id,
    doctor.name AS doctor_name,
    COUNT(*) AS prescr_count
  FROM appointment
  JOIN doctor ON appointment.doctor_id = doctor.doctor_id
  JOIN prescription ON prescription.appointment_id = appointment.appointment_id
  GROUP BY doctor.doctor_id, doctor.name
)
SELECT *,
       ROW_NUMBER() OVER (ORDER BY prescr_count DESC) AS _rank
FROM doc_prescr_count;

-- Number of prescriptions written by each doctor (sorted)
-- Nombre d’ordonnances rédigées par chaque médecin (trié)

 SELECT
  doctor.doctor_id,
  doctor.name AS doctor_name,
  COUNT(prescription.prescription_id) AS prescr_count
FROM appointment
JOIN doctor ON appointment.doctor_id = doctor.doctor_id
JOIN prescription ON prescription.appointment_id = appointment.appointment_id
GROUP BY doctor.doctor_id, doctor.name
ORDER BY prescr_count DESC;
 
 
-- Patient age analysis with medication details by appointment
-- Analyse de l’âge des patients avec les détails des médicaments par rendez-vous
  
SELECT 
trim(patient.name) as patient_name, patient.dob, 
timestampdiff(year, dob, now()) as age, prescription.medication_id, medication.name, medication.dosage_form, medication.strength, 
medication.description
  from patient
 JOIN appointment 
 ON appointment.patient_id = patient.patient_id
 JOIN prescription
 ON appointment.appointment_id = prescription.appointment_id
 JOIN medication
 ON medication.medication_id = prescription.medication_id
 ORDER BY age desc;
 
-- Patient age distribution by medication count
-- Répartition des patients par tranche d’âge et nombre de médicaments prescrits

 SELECT age_range,
 COUNT(*) as medic_count 
 FROM (
 SELECT
  timestampdiff(year, dob, now()) as age,
 CASE 
 WHEN timestampdiff(year, dob, now()) >= 18 AND timestampdiff(year, dob, now()) < 36 THEN '18-35'
 WHEN timestampdiff(year, dob, now()) > 35 AND timestampdiff(year, dob, now()) < 50 THEN '36-49'
 WHEN timestampdiff(year, dob, now()) > 49 THEN '50+'
 ELSE '0-18'
 END as age_range, medication.name
 FROM patient
 JOIN appointment 
 ON appointment.patient_id = patient.patient_id
 JOIN prescription
 ON appointment.appointment_id = prescription.appointment_id
 JOIN medication
 ON medication.medication_id = prescription.medication_id) as ages
 GROUP BY age_range;
 
 
-- A list of all appointments for a particular patient  
-- Liste de tous les rendez-vous d’un patient donné  

 SELECT 
trim(patient.name) as patient_name, patient.dob, 
timestampdiff(year, dob, now()) as age, prescription.medication_id, medication.name, medication.dosage_form, medication.strength, 
medication.description
  from patient
  JOIN appointment 
 ON appointment.patient_id = patient.patient_id
 JOIN prescription
 ON appointment.appointment_id = prescription.appointment_id
 JOIN medication
 ON medication.medication_id = prescription.medication_id
  WHERE patient.name LIKE '%Gard%'
 ORDER BY age desc;
 
 
-- Top 5 most prescribed medications  
-- Top 5 des médicaments les plus prescrits  

 SELECT medication.medication_id, medication.name, COUNT(medication.medication_id) as med_count
 FROM medication
  JOIN prescription
 ON prescription.medication_id = medication.medication_id
 GROUP BY medication.medication_id
 ORDER BY med_count desc
 LIMIT 5;
 
-- Percentage of completed and canceled appointments  
-- Pourcentage de rendez-vous effectués et annulés  
 
 SELECT * from appointment;
  
 SELECT
 ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS per_cent_completed,
 ROUND (SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*)*100, 2) as per_cent_cancelled,
 ROUND (SUM(CASE WHEN status IS NULL THEN 1 else 0 END) / COUNT(*)*100, 2) as per_cent_unknown
  FROM appointment;
 
-- Number of patients per doctor per week  
-- Nombre de patients par médecin et par semaine  

 SELECT doctor.doctor_id, doctor.name, 
 YEAR(appointment.appointment_date) as _year,
 WEEK(appointment.appointment_date, 1) as _week,
 COUNT(patient.patient_id) as patient_count
 FROM doctor
 JOIN appointment
 ON appointment.doctor_id = doctor.doctor_id
 JOIN patient
 ON appointment.patient_id = patient.patient_id
 GROUP BY _year, _week, doctor_id 
 ORDER BY _year, _week;




 
