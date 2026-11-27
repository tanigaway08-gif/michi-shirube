require "rails_helper"

RSpec.describe Trip, type: :model do
  describe "バリデーション" do
    it "有効な属性であれば登録できる" do
      trip = build(:trip)
      expect(trip).to be_valid
    end

    %i[duration budget departure transport companion title prefecture].each do |attr|
      it "#{attr}が空の場合は無効である" do
        trip = build(:trip, attr => nil)
        expect(trip).to be_invalid
        expect(trip.errors[attr]).to be_present
      end
    end

    it "budgetが0未満の場合は無効である" do
      trip = build(:trip, budget: -1)
      expect(trip).to be_invalid
    end

    it "budgetが小数の場合は無効である" do
      trip = build(:trip, budget: 1000.5)
      expect(trip).to be_invalid
    end

    it "share_tokenが重複している場合は無効である" do
      existing_trip = create(:trip)
      duplicate_trip = build(:trip, share_token: existing_trip.share_token)
      expect(duplicate_trip).to be_invalid
      expect(duplicate_trip.errors[:share_token]).to be_present
    end
  end

  describe "アソシエーション" do
    it "複数のschedulesを持てる" do
      trip = create(:trip)
      create_list(:schedule, 2, trip: trip)
      expect(trip.schedules.count).to eq(2)
    end

    it "tripを削除すると紐づくschedulesも削除される" do
      trip = create(:trip)
      create(:schedule, trip: trip)
      expect { trip.destroy }.to change(Schedule, :count).by(-1)
    end

    it "schedulesはday_numberとstart_timeの昇順で取得される" do
      trip = create(:trip)
      late = create(:schedule, trip: trip, day_number: 1, start_time: "14:00")
      early = create(:schedule, trip: trip, day_number: 1, start_time: "09:00")
      expect(trip.schedules.reload).to eq([ early, late ])
    end
  end

  describe "enum" do
    it "durationが正しく定義されている" do
      trip = build(:trip, duration: :day_trip)
      expect(trip.duration_day_trip?).to be true
    end

    it "transportが正しく定義されている" do
      trip = build(:trip, transport: :car)
      expect(trip.transport_car?).to be true
    end

    it "companionが正しく定義されている" do
      trip = build(:trip, companion: :family)
      expect(trip.companion_family?).to be true
    end

    it "prefectureが正しく定義されている" do
      trip = build(:trip, prefecture: :osaka)
      expect(trip.osaka?).to be true
    end
  end

  describe "コールバック・メソッド" do
    it "作成時にshare_tokenが自動生成される" do
      trip = create(:trip, share_token: nil)
      expect(trip.share_token).to be_present
    end

    it "to_paramがshare_tokenを返す" do
      trip = create(:trip)
      expect(trip.to_param).to eq(trip.share_token)
    end

    it "detect_prefectureがエリア文字列から都道府県を判定できる" do
      expect(Trip.detect_prefecture("京都府 京都市")).to eq(:kyoto)
      expect(Trip.detect_prefecture("")).to eq(:osaka)
    end
  end
end
