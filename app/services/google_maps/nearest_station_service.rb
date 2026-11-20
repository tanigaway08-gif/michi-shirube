module GoogleMaps
  class NearestStationService
    ENDPOINT = "https://places.googleapis.com/v1/places:searchNearby"

    def initialize(lat:, lng:)
      @lat = lat.to_f
      @lng = lng.to_f
      @api_key = ENV.fetch("GOOGLE_MAPS_API_KEY", nil)
    end

    def call
      return { error: "APIキーが設定されていません" } if @api_key.blank?

      response = connection.post(ENDPOINT) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["X-Goog-Api-Key"] = @api_key
        # FieldMaskで必要な項目（駅名・住所）だけに絞ることで通信量とAPI課金を最小化
        req.headers["X-Goog-FieldMask"] = "places.displayName,places.shortFormattedAddress"
        req.body = request_body.to_json
      end

      parse_response(response)
    rescue Faraday::TimeoutError
      { error: "通信がタイムアウトしました。もう一度お試しください🐾" }
    rescue Faraday::Error => e
      Rails.logger.error("Google Maps API Error: #{e.message}")
      { error: "駅情報の取得に失敗しました。手入力をお試しください🐾" }
    end

    private

    def connection
      Faraday.new do |f|
        # タイムアウト設定（接続3秒・応答5秒で打ち切り、画面が固まるのを防ぐ）
        f.options.open_timeout = 3
        f.options.timeout = 5
      end
    end

    def request_body
      {
        includedTypes: [ "train_station", "subway_station" ],
        maxResultCount: 5,
        rankPreference: "DISTANCE", # 距離が近い順に並べる
        languageCode: "ja",
        locationRestriction: {
          circle: {
            center: {
              latitude: @lat,
              longitude: @lng
            },
            radius: 3000.0 # 現在地から半径3km以内で検索
          }
        }
      }
    end

    def parse_response(response)
      unless response.success?
        Rails.logger.error("Google Maps API HTTP #{response.status}: #{response.body}")
        return { error: "最寄駅の検索に失敗しました🐾" }
      end

      data = JSON.parse(response.body)
      places = data["places"] || []

      stations = places.map do |place|
        {
          name: place.dig("displayName", "text"),
          address: place["shortFormattedAddress"]
        }
      end.uniq { |s| s[:name] }

      { stations: stations }
    end
  end
end
