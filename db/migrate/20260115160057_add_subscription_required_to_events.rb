class AddSubscriptionRequiredToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :subscription_required, :boolean, default: true
  end
end
