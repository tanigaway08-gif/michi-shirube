# frozen_string_literal: true

module Openai
  class TripPlannerService
    class Error < StandardError; end

    MODEL = "gpt-6-luna"
    MAX_COMPLETION_TOKENS = 4000

    DURATION_LABELS = {
      "morning" => "午前のみ（目安：3〜4時間）",
      "afternoon" => "午後のみ（目安：4〜5時間）",
      "day_trip" => "日帰り・1日（目安：8〜10時間）"
    }.freeze

    BUDGET_LABELS = {
      3000 => "〜3,000円（気軽にサクッと）",
      5000 => "〜5,000円（定番お出かけ）",
      10_000 => "〜10,000円（ちょっと贅沢）",
      15_000 => "10,000円以上（たっぷり満喫）"
    }.freeze

    TRANSPORT_LABELS = {
      "public_transit" => "電車・バス",
      "car" => "車",
      "walk" => "徒歩・自転車"
    }.freeze

    COMPANION_LABELS = {
      "solo" => "ひとり旅",
      "couple" => "カップル・夫婦",
      "friends" => "友人と",
      "family" => "家族と"
    }.freeze

    def initialize(duration:, budget:, departure:, transport:, companion:)
      @duration = duration.to_s
      @budget = budget.to_i
      @departure = departure.to_s.strip
      @transport = transport.to_s
      @companion = companion.to_s
    end

    def call
      return mock_response if ENV["USE_MOCK_OPENAI"] == "true"

      response = client.chat(
        parameters: {
          model: MODEL,
          reasoning_effort: "low",
          response_format: { type: "json_object" },
          max_completion_tokens: MAX_COMPLETION_TOKENS,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ]
        }
      )

      if response["error"].present?
        Rails.logger.error("[Openai::TripPlannerService] OpenAI Error: #{response['error']}")
        raise Error, "AIとの通信でエラーが発生しました（#{response.dig('error', 'message')}）"
      end

      content = response.dig("choices", 0, "message", "content")
      raise Error, "AIからの応答が空でした。" if content.blank?

      parsed = JSON.parse(content)
      validate_response!(parsed)
      parsed
    rescue Faraday::TimeoutError => e
      Rails.logger.error("[Openai::TripPlannerService] Timeout: #{e.message}")
      raise Error, "応答がタイムアウトしました。時間をおいて再度お試しください。"
    rescue Faraday::Error => e
      Rails.logger.error("[Openai::TripPlannerService] API Error: #{e.message}")
      raise Error, "旅行プランの生成中に通信エラーが発生しました。"
    rescue JSON::ParserError => e
      Rails.logger.error("[Openai::TripPlannerService] JSON Parse Error: #{e.message}")
      raise Error, "旅行プランの読み込みに失敗しました。もう一度お試しください。"
    end

    private

    def client
      @client ||= OpenAI::Client.new
    end

    def system_prompt
      <<~PROMPT
        あなたは日本の日帰り・短時間旅行に詳しい「しるべ駅長」の旅行プランナーです。
        ユーザーの5つの条件に基づき、実在する日本のエリア・スポットで構成された魅力的な旅行プランを3案提案してください。

        # ルール
        - 必ず有効なJSONのみを出力すること（前置きやマークダウン記号は不要）。
        - 3案はそれぞれ雰囲気や方向性が異なる提案にすること（例：王道観光、グルメ・カフェ、自然・癒やし）。
        - 出発地と交通手段、旅行時間に対して無理のない移動距離・スケジュールにすること。
        - 各プランのスポット数は3〜4箇所に絞ること。
        - 各スポットの説明（description）は40文字以内で簡潔にすること。
        - 実在する一般的なスポット名・エリア名を使うこと。
        - 金額はすべて「1人あたり」の目安で統一すること。
        - プランの目安予算（estimated_budget）は、各スポットの目安金額の合計に、往復交通費やちょっとした飲食・お土産代を加えた現実的な金額にすること。

        # 出力JSONフォーマット
        {
          "plans": [
            {
              "title": "プランのキャッチコピー（20文字以内）",
              "area": "都道府県・エリア名（例：兵庫県 神戸・元町）",
              "summary": "プランの概要（60文字以内）",
              "estimated_budget": "目安予算（例：約4,500円）",
              "travel_time": "出発地からの移動目安（例：電車で約30分）",
              "spots": [
                {
                  "time": "10:00",
                  "name": "スポット名",
                  "estimated_cost": "目安金額（例：約1,500円、無料）",
                  "category": "グルメ / 観光 / カフェ / 自然 / 体験 のいずれか",
                  "description": "見どころや楽しみ方（40文字以内）"
                }
              ]
            }
          ]
        }
      PROMPT
    end

    def user_prompt
      <<~PROMPT
        以下の条件で旅行プランを3案作成してください。

        - 旅行時間: #{DURATION_LABELS.fetch(@duration, @duration)}
        - 予算: #{BUDGET_LABELS.fetch(@budget, "#{@budget}円")}
        - 出発地: #{@departure}
        - 交通手段: #{TRANSPORT_LABELS.fetch(@transport, @transport)}
        - 同行者: #{COMPANION_LABELS.fetch(@companion, @companion)}
      PROMPT
    end

    def validate_response!(parsed)
      plans = parsed["plans"]
      return if plans.is_a?(Array) && plans.size == 3

      raise Error, "旅行プランの形式が正しくありませんでした。"
    end

    def mock_response
      {
        "plans" => [
          {
            "title" => "港町の異国情緒とカフェ巡り",
            "area" => "兵庫県 神戸・元町",
            "summary" => "#{@departure}から気軽に行ける、海辺の散策と人気ベーカリーを楽しむ王道コースです。",
            "estimated_budget" => "約4,200円",
            "travel_time" => "電車で約30分",
            "spots" => [
              { "time" => "10:00", "name" => "南京町", "category" => "グルメ", "estimated_cost" => "約1,500円", "description" => "食べ歩きで熱々の豚まんや小籠包を満喫。" },
              { "time" => "12:00", "name" => "メリケンパーク", "category" => "観光", "estimated_cost" => "約1,500円", "description" => "海風を感じながら港のシンボルを背景に記念撮影。" },
              { "time" => "14:00", "name" => "旧居留地カフェ", "category" => "カフェ", "estimated_cost" => "約1,500円", "description" => "レトロな洋館で香り高いコーヒーとケーキを一息。" }
            ]
          },
          {
            "title" => "古都の路地裏と抹茶スイーツ旅",
            "area" => "京都府 宇治",
            "summary" => "川沿いの穏やかな景色と本場の宇治茶グルメをのんびり味わう癒やし旅です。",
            "estimated_budget" => "約4,800円",
            "travel_time" => "電車で約50分",
            "spots" => [
              { "time" => "10:30", "name" => "平等院鳳凰堂", "category" => "観光", "estimated_cost" => "約1,500円", "description" => "池に映る優美な姿と庭園をゆっくり鑑賞。" },
              { "time" => "12:30", "name" => "宇治橋通り商店街", "category" => "グルメ", "estimated_cost" => "約1,500円", "description" => "茶そばランチで京都らしい味わいを堪能。" },
              { "time" => "14:30", "name" => "老舗茶舗の甘味処", "category" => "カフェ", "estimated_cost" => "約1,500円", "description" => "濃厚な抹茶パフェで旅の締めくくり。" }
            ]
          },
          {
            "title" => "緑あふれる公園と絶品ランチ",
            "area" => "大阪府 箕面",
            "summary" => "自然の中でリフレッシュしながら、名物グルメも楽しめるアクティブコースです。",
            "estimated_budget" => "約3,500円",
            "travel_time" => "電車で約35分",
            "spots" => [
              { "time" => "10:00", "name" => "箕面大滝", "category" => "自然", "estimated_cost" => "約1,500円", "description" => "マイナスイオンたっぷりの遊歩道をハイキング。" },
              { "time" => "12:30", "name" => "滝道沿いの古民家カフェ", "category" => "グルメ", "estimated_cost" => "約1,500円", "description" => "地元野菜を使った彩り豊かなランチプレート。" },
              { "time" => "14:30", "name" => "もみじの天ぷら専門店", "category" => "観光", "estimated_cost" => "約1,500円", "description" => "揚げたてサクサクのご当地名物をお土産に。" }
            ]
          }
        ]
      }
    end
  end
end
