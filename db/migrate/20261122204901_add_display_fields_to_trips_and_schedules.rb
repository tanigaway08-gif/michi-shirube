class AddDisplayFieldsToTripsAndSchedules < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :area, :string
    add_column :trips, :travel_time, :string
    add_column :schedules, :category, :string
    add_column :schedules, :estimated_cost, :string
  end
end
