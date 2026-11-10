class Schedule < ApplicationRecord
  belongs_to :trip

  validates :start_time, :place_name, :day_number, presence: true
  validates :day_number, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
