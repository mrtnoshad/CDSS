
-- 
-- Patients receiving 1-100u per dose inpatient subQ insulin that is not a pump, U500, or a rare order (<25 orders in dataset)
-- Verified that dose was given, dose 1-100, insulins as expected when removing pumps, partial units, insulins ordered <25x
-- If ORDER BY units DESC, top 10 rows should be 98-95U and time 2012 (1) & 2011 (10)
WITH inpt_insulin_given AS ( 
  SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, mar.taken_time_jittered FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
    LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
    WHERE mar.order_med_id_coded in 
    (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
         WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
         AND (medord2.ordering_mode_c) = 2 -- inpatient
         AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
         AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
         AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
         AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
        AND (medord2.med_description) NOT IN ("INSULIN REGULAR 100 UNIT/ML SC VERY AGGRESSIVE SCALE FEEDING (BEDTIME)", "INSULIN GLULISINE 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", " INV - INSULIN LISPRO SC (ORAL DIETS/BOLUS FEEDS) INTERVENTION", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN ASPART 100 UNIT/ML AGGRESSIVE SCALE FEEDING", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN") -- removes any insulin ordered < 10-25 times, conveniently excluding any U200 or U300
        AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
        AND medord2.med_route = 'Subcutaneous'
        ) --and subQ
      AND (mar.mar_action) IN ('Given') --medication actually given
      AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
      AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
      AND mar.sig <> "0-10"
      AND CAST(mar.sig AS float64) > 0
      AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
      AND mar.sig IS NOT NULL 
      AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
      AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
    ),

--
-- Pt encounters with creatinine > 2 (will use to exclude hospitalizations where pt had Cr > 2)
-- If DISTINCT pt encounters & ORDER BY pt encounter, top 5 will end in 6-6-6-0-9
cr_over_2 AS (
  SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- patient encounters with creatinine >2 
      WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
      AND ord_num_value != 9999999
      AND taken_time_jittered IS NOT null
      AND ord_num_value > 2
      ),

-- 
-- 
inpt_insulin_given_noAKI AS ( 
  SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, mar.taken_time_jittered FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
    LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
    WHERE mar.order_med_id_coded in 
    (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
         WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
         AND (medord2.ordering_mode_c) = 2 -- inpatient
         AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
         AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
         AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
         AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
        AND (medord2.med_description) NOT IN ("INSULIN REGULAR 100 UNIT/ML SC VERY AGGRESSIVE SCALE FEEDING (BEDTIME)", "INSULIN GLULISINE 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", " INV - INSULIN LISPRO SC (ORAL DIETS/BOLUS FEEDS) INTERVENTION", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN ASPART 100 UNIT/ML AGGRESSIVE SCALE FEEDING", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN") -- removes any insulin ordered < 10-25 times, conveniently excluding any U200 or U300
        AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
        AND medord2.med_route = 'Subcutaneous'
        ) --and subQ
      AND (mar.mar_action) IN ('Given') --medication actually given
      AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
      AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
      AND mar.sig <> "0-10"
      AND CAST(mar.sig AS float64) > 0
      AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
      AND mar.sig IS NOT NULL 
      AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
      AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
      AND mar.pat_enc_csn_id_coded NOT IN 
        (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
        WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
        AND ord_num_value != 9999999
        AND taken_time_jittered IS NOT null
        AND ord_num_value > 2
        )
      ),


--
-- Glucose by meter
gluc_by_meter AS (
      SELECT a.rit_uid, DATE(a.taken_time_jittered) as date FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as a 
        WHERE UPPER(a.lab_name) LIKE '%GLUCOSE%' 
        AND a.lab_name = "Glucose by Meter"
        AND UPPER(a.ordering_mode) = 'INPATIENT' AND a.ord_num_value BETWEEN 0 AND 9999998
      ),

--
-- patient + date where BG <100 or >180
-- Date 10 should be 9/24, Date 76 should be 3/17
days_outofrange AS (
  SELECT b.rit_uid, DATE(b.taken_time_jittered) as date FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as b
    WHERE UPPER(b.lab_name) LIKE '%GLUCOSE%' 
    AND b.lab_name = "Glucose by Meter"
    AND UPPER(b.ordering_mode) = 'INPATIENT' AND b.ord_num_value BETWEEN 0 AND 9999998
    AND b.ord_num_value NOT BETWEEN 100 AND 180 

  GROUP BY b.rit_uid, date
  ORDER BY rit_uid, date
  ),

--
-- patiet encounters excluding insulins ordered <25x/pumps/U500, where basal insulin was ordered subQ and inpatient
-- Distinct order by pt encounter top 5 end with 7-8-9-4-0
basal_ordered AS (
  SELECT medord2.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2 -- excludes patients who had basal insulin ordered * except for 2 orders of NPH that are excluded above
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND (medord2.med_description) NOT IN ("INSULIN REGULAR 100 UNIT/ML SC VERY AGGRESSIVE SCALE FEEDING (BEDTIME)", "INSULIN GLULISINE 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", " INV - INSULIN LISPRO SC (ORAL DIETS/BOLUS FEEDS) INTERVENTION", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN ASPART 100 UNIT/ML AGGRESSIVE SCALE FEEDING", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN") -- removes any insulin ordered <10-25 times, conveniently excluding any U200 or U300
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous' --and subQ
       AND UPPER(medord2.med_description) IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP", "NPH INSULIN HUMAN RECOMB 100 UNIT/ML SC SUSP", "INSULIN GLARGINE 100 UNIT/ML SC SOLN", "INSULIN DETEMIR 100 UNIT/ML SC SOLN", "INSULIN NPH ISOPH U-100 HUMAN 100 UNIT/ML SC SUSP", "INSULIN DETEMIR U-100 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70/30) SUBCUTANEOUS VIAL", "INSULIN DETEMIR 100 UNIT/ML (3 ML) SC INPN", "INSULIN DETEMIR U-100 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (50-50) SC SUSP", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP","INSULIN DETEMIR 100 UNIT/ML SC INPN", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC INPN") -- patients ordered for basal)
),

--
-- Weight converted from oz to Kg for pts getting inpatient insulin subQ not on pump/u500/ordered <25x 
-- Note that "meas value" in the flowsheet contains real dates **do not download**, num_value2 may have some data but appears unreliable 
weight_pt_getting_insulin AS (
SELECT rit_uid, row_disp_name, num_value1, (num_value1*0.028) AS KG, recorded_time_jittered FROM `som-nero-phi-jonc101.starr_datalake2018.flowsheet`
-- SELECT (num_value1*0.028) AS KG, count(meas_value) as count  FROM `som-nero-phi-jonc101.starr_datalake2018.flowsheet` 
  WHERE rit_uid IN (SELECT mar.jc_uid FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
    LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
    WHERE mar.order_med_id_coded in 
    (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
         WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
         AND (medord2.ordering_mode_c) = 2 -- inpatient
         AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
         AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
         AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
         AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
        AND (medord2.med_description) NOT IN ("INSULIN REGULAR 100 UNIT/ML SC VERY AGGRESSIVE SCALE FEEDING (BEDTIME)", "INSULIN GLULISINE 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", " INV - INSULIN LISPRO SC (ORAL DIETS/BOLUS FEEDS) INTERVENTION", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN ASPART 100 UNIT/ML AGGRESSIVE SCALE FEEDING", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN") -- removes any insulin ordered < 10-25 times, conveniently excluding any U200 or U300
        AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
        AND medord2.med_route = 'Subcutaneous'
        ) --and subQ
    AND (mar.mar_action) IN ('Given') --medication actually given
    AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
    AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
    AND mar.sig <> "0-10"
    AND CAST(mar.sig AS float64) > 0
    AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
    AND mar.sig IS NOT NULL 
    AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
    AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
  )

AND row_disp_name LIKE "Weight"
AND num_value1 IS NOT NULL --numeric value exists
)

--
-- wt, time, age table for adults who got subQ insulin with wt > 45kg and < doubling in weight between time in flowsheet and "most recent wt"
recent_wt_flowsht_insulin AS (
SELECT dem.rit_uid, DATE_DIFF(DATE(flow.recorded_time_jittered), (dem.birth_date_jittered), YEAR) as ageYears, flow.row_disp_name, flow.meas_value, flow.recorded_time_jittered, (flow.num_value1*0.028) AS KG, dem.recent_wt_in_kgs, (dem.recent_wt_in_kgs-(flow.num_value1*0.028)) as wt_diff, ((dem.recent_wt_in_kgs-(flow.num_value1*0.028))/dem.recent_wt_in_kgs) as wt_diff_percent, bmi FROM `som-nero-phi-jonc101.starr_datalake2018.flowsheet` AS flow
INNER JOIN `som-nero-phi-jonc101.starr_datalake2018.demographic` AS dem ON dem.rit_uid = flow.rit_uid 
WHERE dem.rit_uid IN 
  (SELECT rit_uid,FROM `som-nero-phi-jonc101.starr_datalake2018.flowsheet` where inpatient_data_id_coded IN
    (SELECT pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.mar` WHERE order_med_id_coded in --patient received subQ insulin
      (SELECT order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` 
       WHERE UPPER(med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (ordering_mode_c) = 2 -- inpatient
       AND med_route = 'Subcutaneous') --and subQ
    AND (mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push')
   AND (mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed')
   AND dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND sig <> "0-10"
   AND sig IS NOT NULL 
   AND sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   )
  )
AND row_disp_name LIKE "Weight"
AND UPPER(meas_value) NOT LIKE "%W%" -- removes "XweeksXdays"-- presumed misentered data
AND UPPER(meas_value) NOT LIKE "%/%" -- Removes fractions of lbs
AND UPPER(meas_value) NOT LIKE "%GMS%" --Removes gms
AND UPPER(meas_value) NOT LIKE "%LBS%" -- Removes lbs
AND UPPER(meas_value) NOT LIKE "% G%" -- Removes grams 
AND num_value1 IS NOT NULL --numeric value exists
AND (flow.num_value1*0.028) > 45 -- wt > 45kg (99lbs)
AND DATE_DIFF(DATE(flow.recorded_time_jittered), (dem.birth_date_jittered), YEAR) >= 18 -- ADULTS ONLY
AND dem.recent_wt_in_kgs != 0 -- recent wt not equal zero (there are no pts with recent wt = 0 but if I don't do this the percent returns an error)
AND ((dem.recent_wt_in_kgs-(flow.num_value1*0.028))/dem.recent_wt_in_kgs) < 0.5 -- Pt did not > double in wt (Quality control)
)


