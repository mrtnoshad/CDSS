#!/bin/sh -x
# Define constants for connecting to database from which to dump tables.
# For example, if dumping from local database named test_database and accessing
# as user test_user, you would use the following lines:
# export DB_HOST=localhost
# export DB_DSN=test_database
# export DB_USER=test_user
export DB_HOST=database_host_name
export DB_DSN=database_source_name
export DB_USER=database_user_name

gzip -d -c stride_admit.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_adt.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_chargemaster.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_culture_micro.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_drg.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_dx_list.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_flowsheet.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_icd9_cm.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_icd10_cm.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_income.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_io_flowsheet.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_mapped_meds.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_medication_mpi.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_note.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_order_med.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_order_medmixinfo.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_order_proc.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_order_results.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_orderset_order_med.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_orderset_order_proc.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_patient_encounter.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_patient.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_preadmit_med.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
gzip -d -c stride_treatment_team.dump.sql.gz | psql -h $DB_HOST -U $DB_USER $DB_DSN
