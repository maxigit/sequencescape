Study.transaction do
  ["DROP TABLE IF EXISTS study_samples_backup;", \
  "CREATE TABLE study_samples_backup SELECT * FROM study_samples;", \
  "CREATE TEMPORARY TABLE study_samples_uniq SELECT DISTINCT study_id, sample_id FROM study_samples;", \
  "TRUNCATE TABLE study_samples;", \
  "INSERT INTO study_samples (study_id, sample_id) SELECT study_id, sample_id FROM study_samples_uniq;" \
  ].each do |statement|
    Study.connection.execute(statement)
  end
end
