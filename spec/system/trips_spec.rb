require "rails_helper"

RSpec.describe "旅のしおり作成フロー", type: :system do
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }
  let(:mock_plans) do
    {
      "plans" => [
        {
          "title" => "京都ゆったり日帰り旅",
          "area" => "京都府 京都市",
          "summary" => "古都の街並みとグルメを楽しむ1日プランです。",
          "estimated_budget" => "約8,000円",
          "travel_time" => "約1時間",
          "spots" => [
            {
              "time" => "10:00",
              "name" => "清水寺",
              "category" => "観光",
              "estimated_cost" => "約500円",
              "description" => "朝の澄んだ空気の中で参拝します。"
            },
            {
              "time" => "12:30",
              "name" => "祇園ランチ",
              "category" => "グルメ",
              "estimated_cost" => "約2,000円",
              "description" => "京料理を堪能します。"
            }
          ]
        }
      ]
    }
  end

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)

    service_double = instance_double(Openai::TripPlannerService, call: mock_plans)
    allow(Openai::TripPlannerService).to receive(:new).and_return(service_double)
  end

  it "トップ画面から5つの条件を選択し、AI提案からしおりを作成・表示できる" do
    # 1. トップ画面 → はじめる
    visit root_path
    click_link "はじめる"

    # 2. STEP 1: 旅行時間
    expect(page).to have_current_path(step1_trips_path)
    find("button[name='duration'][value='day_trip']").click

    # 3. STEP 2: 予算
    expect(page).to have_current_path(step2_trips_path)
    find("button[name='budget'][value='10000']").click

    # 4. STEP 3: 出発地（※テキスト入力の場合は fill_in に調整）
    expect(page).to have_current_path(step3_trips_path)
    if page.has_field?("departure")
      fill_in "departure", with: "大阪駅"
      find("button[type='submit'], input[type='submit']").click
    else
      first("button[name='departure']").click
    end

    # 5. STEP 4: 交通手段
    expect(page).to have_current_path(step4_trips_path)
    find("button[name='transport'][value='public_transit']").click

    # 6. STEP 5: 同行者
    expect(page).to have_current_path(step5_trips_path)
    find("button[name='companion'][value='couple']").click

    # 7. 確認画面 → AI提案を実行
    expect(page).to have_current_path(confirm_trips_path)
    expect(page).to have_content("日帰り（1日）")
    click_button "この条件で旅先を3つ探す！"

    # 8. 提案一覧画面 → プラン詳細へ
    expect(page).to have_current_path(proposals_path)
    expect(page).to have_content("京都ゆったり日帰り旅")
    click_link "詳しいスケジュールを見る 🐾"

    # 9. プラン詳細画面 → しおりを作成
    expect(page).to have_current_path(proposal_path(0))
    expect {
      find("form[action='#{trips_path}'] button[type='submit'], form[action='#{trips_path}'] input[type='submit']").click
    }.to change(Trip, :count).by(1).and change(Schedule, :count).by(2)

    # 10. しおり詳細画面の表示確認
    created_trip = Trip.last
    expect(page).to have_current_path(trip_path(created_trip))
    expect(page).to have_content("京都ゆったり日帰り旅")
    expect(page).to have_content("清水寺")
    expect(page).to have_content("祇園ランチ")
  end
end
