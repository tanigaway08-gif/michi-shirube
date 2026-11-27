FactoryBot.define do
  factory :trip do
    duration { :day_trip }
    budget { 10_000 }
    departure { "大阪駅" }
    transport { :public_transit }
    companion { :couple }
    title { "京都ゆったり日帰り旅" }
    prefecture { :kyoto }
    area { "京都府 京都市" }
    travel_time { "約1時間" }
    description { "古都の街並みとグルメを楽しむ1日プランです。" }
  end
end
