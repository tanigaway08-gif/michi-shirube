class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.integer :duration, null: false
      t.integer :budget, null: false
      t.string :departure, null: false
      t.integer :transport, null: false
      t.integer :companion, null: false
      t.string :title, null: false
      t.integer :prefecture, null: false
      t.text :description
      t.integer :estimated_cost
      t.string :share_token, null: false
      t.string :extra_conditions
      t.boolean :is_visited, default: false, null: false

      t.timestamps
    end
    add_index :trips, :share_token, unique: true
  end
end
