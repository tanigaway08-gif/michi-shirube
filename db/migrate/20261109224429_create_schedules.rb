class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :start_time, null: false
      t.string :place_name, null: false
      t.text :content
      t.integer :day_number, null: false, default: 1

      t.timestamps
    end
  end
end
