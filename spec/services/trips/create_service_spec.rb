require "rails_helper"

RSpec.describe Trips::CreateService, type: :service do
  let(:trip_params) do
    {
      "duration" => "day_trip",
      "budget" => 10_000,
      "departure" => "大阪駅",
      "transport" => "public_transit",
      "companion" => "couple"
    }
  end

  let(:plan) do
    {
      "title" => "京都ゆったり日帰り旅",
      "area" => "京都府 京都市",
      "summary" => "古都の街並みを楽しむ1日プラン",
      "estimated_budget" => "約7,000〜10,000円",
      "travel_time" => "約1時間",
      "spots" => [
        {
          "time" => "10:00",
          "name" => "清水寺",
          "category" => "観光",
          "estimated_cost" => "約500円",
          "description" => "参拝します。"
        }
      ]
    }
  end

  describe "#call" do
    it "TripとScheduleをトランザクション内で保存し、estimated_costを数値変換して返す" do
      service = described_class.new(plan: plan, trip_params: trip_params)

      expect { service.call }
        .to change(Trip, :count).by(1)
        .and change(Schedule, :count).by(1)

      trip = Trip.last
      expect(trip.title).to eq("京都ゆったり日帰り旅")
      expect(trip.estimated_cost).to eq(7000)
      expect(trip.schedules.first.place_name).to eq("清水寺")
    end

    it "Scheduleの保存に失敗した場合はTripもロールバックされる" do
      invalid_plan = plan.merge(
        "spots" => [ { "time" => nil, "name" => nil } ]
      )
      service = described_class.new(plan: invalid_plan, trip_params: trip_params)

      expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Trip.count).to eq(0)
      expect(Schedule.count).to eq(0)
    end
  end
end
