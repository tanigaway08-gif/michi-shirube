class Trip < ApplicationRecord
  has_many :schedules, -> { order(:day_number, :start_time) }, dependent: :destroy

  before_validation :generate_share_token, on: :create

# enum定義（Rails 8構文）

enum :duration, {
    morning: 0,              # 午前のみ（MVP）
    afternoon: 1,            # 午後のみ（MVP）
    day_trip: 2,             # 日帰り・1日（MVP）
    one_night: 3,            # 1泊2日（本リリースでUI解放）
    two_nights: 4,           # 2泊3日（本リリースでUI解放）
    three_nights_or_more: 5  # 3泊以上（本リリースでUI解放）
  }, prefix: true

  enum :transport, {
    public_transit: 0,       # 公共交通機関（電車・バス）
    car: 1,                  # 車（レンタカー・自家用車）
    other: 2                 # その他・こだわらない
  }, prefix: true

  enum :companion, {
    solo: 0,                 # ひとり旅
    couple: 1,               # カップル・夫婦
    family: 2,               # 家族
    friends: 3,              # 友人
    other: 4                 # その他・こだわらない
  }, prefix: true

  enum :prefecture, {
    hokkaido: 1, aomori: 2, iwate: 3, miyagi: 4, akita: 5, yamagata: 6, fukushima: 7,
    ibaraki: 8, tochigi: 9, gunma: 10, saitama: 11, chiba: 12, tokyo: 13, kanagawa: 14,
    niigata: 15, toyama: 16, ishikawa: 17, fukui: 18, yamanashi: 19, nagano: 20,
    gifu: 21, shizuoka: 22, aichi: 23, mie: 24, shiga: 25, kyoto: 26, osaka: 27,
    hyogo: 28, nara: 29, wakayama: 30, tottori: 31, shimane: 32, okayama: 33,
    hiroshima: 34, yamaguchi: 35, tokushima: 36, kagawa: 37, ehime: 38, kochi: 39,
    fukuoka: 40, saga: 41, nagasaki: 42, kumamoto: 43, oita: 44, miyazaki: 45,
    kagoshima: 46, okinawa: 47
  }

  validates :duration, :budget, :departure, :transport, :companion, :title, :prefecture, presence: true
  validates :budget, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :share_token, presence: true, uniqueness: true

  PREFECTURE_NAMES = {
    "北海道" => :hokkaido, "青森" => :aomori, "岩手" => :iwate, "宮城" => :miyagi,
    "秋田" => :akita, "山形" => :yamagata, "福島" => :fukushima, "茨城" => :ibaraki,
    "栃木" => :tochigi, "群馬" => :gunma, "埼玉" => :saitama, "千葉" => :chiba,
    "東京" => :tokyo, "神奈川" => :kanagawa, "新潟" => :niigata, "富山" => :toyama,
    "石川" => :ishikawa, "福井" => :fukui, "山梨" => :yamanashi, "長野" => :nagano,
    "岐阜" => :gifu, "静岡" => :shizuoka, "愛知" => :aichi, "三重" => :mie,
    "滋賀" => :shiga, "京都" => :kyoto, "大阪" => :osaka, "兵庫" => :hyogo,
    "奈良" => :nara, "和歌山" => :wakayama, "鳥取" => :tottori, "島根" => :shimane,
    "岡山" => :okayama, "広島" => :hiroshima, "山口" => :yamaguchi, "徳島" => :tokushima,
    "香川" => :kagawa, "愛媛" => :ehime, "高知" => :kochi, "福岡" => :fukuoka,
    "佐賀" => :saga, "長崎" => :nagasaki, "熊本" => :kumamoto, "大分" => :oita,
    "宮崎" => :miyazaki, "鹿児島" => :kagoshima, "沖縄" => :okinawa
  }.freeze

  def to_param
    share_token
  end

  def self.detect_prefecture(area_text)
    return :osaka if area_text.blank?

    matched = PREFECTURE_NAMES.find { |name, _| area_text.include?(name) }
    matched ? matched.last : :osaka
  end

  private

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
