# frozen_string_literal: true

module Trips
  class CreateService
    def initialize(plan:, trip_params:)
      @plan = plan
      @trip_params = trip_params
    end

    def call
      ActiveRecord::Base.transaction do
        trip = create_trip!
        create_schedules!(trip)
        trip
      end
    end

    private

    def create_trip!
      Trip.create!(
        duration: @trip_params["duration"],
        budget: @trip_params["budget"].to_i,
        departure: @trip_params["departure"],
        transport: @trip_params["transport"],
        companion: @trip_params["companion"],
        title: @plan["title"],
        prefecture: Trip.detect_prefecture(@plan["area"]),
        area: @plan["area"],
        travel_time: @plan["travel_time"],
        description: @plan["summary"],
        estimated_cost: extract_cost(@plan["estimated_budget"])
      )
    end

    def create_schedules!(trip)
      Array(@plan["spots"]).each do |spot|
        trip.schedules.create!(
          day_number: 1,
          start_time: spot["time"],
          place_name: spot["name"],
          category: spot["category"],
          estimated_cost: spot["estimated_cost"],
          content: spot["description"]
        )
      end
    end

    def extract_cost(text)
      return nil if text.blank?

      # "約4,200円" や "約7,000〜10,000円" から先頭の数値（4200, 7000）を抽出
      digits = text.tr("０-９，", "0-9,").scan(/\d[\d,]*/).first
      digits&.delete(",")&.to_i
    end
  end
end
