require "rails_helper"

RSpec.describe Schedule, type: :model do
  describe "バリデーション" do
    it "有効な属性であれば登録できる" do
      schedule = build(:schedule)
      expect(schedule).to be_valid
    end

    %i[start_time place_name day_number].each do |attr|
      it "#{attr}が空の場合は無効である" do
        schedule = build(:schedule, attr => nil)
        expect(schedule).to be_invalid
        expect(schedule.errors[attr]).to be_present
      end
    end

    it "day_numberが0以下の場合は無効である" do
      schedule = build(:schedule, day_number: 0)
      expect(schedule).to be_invalid
      expect(schedule.errors[:day_number]).to be_present
    end

    it "day_numberが小数の場合は無効である" do
      schedule = build(:schedule, day_number: 1.5)
      expect(schedule).to be_invalid
      expect(schedule.errors[:day_number]).to be_present
    end
  end

  describe "アソシエーション" do
    it "tripに紐づいていない場合は無効である" do
      schedule = build(:schedule, trip: nil)
      expect(schedule).to be_invalid
      expect(schedule.errors[:trip]).to be_present
    end
  end
end
