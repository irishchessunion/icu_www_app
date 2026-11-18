module ChartDemographics
  AGE_BANDS = ["<18", "18-24", "25-34", "35-44", "45-54", "55-64", "65-74", "75+", "Unknown"].freeze
  GENDERS = ["Male", "Female", "Unknown"].freeze
  GENDER_SQL = "CASE players.gender WHEN 'M' THEN 'Male' WHEN 'F' THEN 'Female' ELSE 'Unknown' END".freeze

  def self.age_sql(reference_sql)
    <<~SQL.squish
      CASE
        WHEN players.dob IS NULL OR players.dob > #{reference_sql} THEN 'Unknown'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 18 THEN '<18'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 25 THEN '18-24'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 35 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 45 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 55 THEN '45-54'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 65 THEN '55-64'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, #{reference_sql}) < 75 THEN '65-74'
        ELSE '75+'
      END
    SQL
  end
end
