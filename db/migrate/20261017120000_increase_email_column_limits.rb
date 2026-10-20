class IncreaseEmailColumnLimits < ActiveRecord::Migration[8.1]
  COLUMNS = { players: :email, clubs: :email, events: :email, carts: :confirmation_email, payment_errors: :confirmation_email }

  def up
    COLUMNS.each { |table, column| change_column table, column, :string }
  end

  def down
    COLUMNS.each { |table, column| change_column table, column, :string, limit: 50 }
  end
end
