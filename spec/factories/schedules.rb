FactoryBot.define do
  factory :schedule do
    association :trip
    day_number { 1 }
    start_time { "10:00" }
    place_name { "清水寺" }
    category { "観光" }
    estimated_cost { "約500円" }
    content { "朝の澄んだ空気の中で参拝します。" }
  end
end
