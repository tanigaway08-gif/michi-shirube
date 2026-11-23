class TripsController < ApplicationController
  before_action :initialize_trip_session, only: %i[
    step1 save_step1
    step2 save_step2
    step3 save_step3
    step4 save_step4
    step5 save_step5
    confirm
  ]

  def new
    session[:trip_params] = {}
    redirect_to step1_trips_path
  end

  def step1
    @duration = session.dig(:trip_params, "duration")
  end

  def save_step1
    if params[:duration].blank?
      flash.now[:alert] = "旅行時間を選択してください🐾"
      render :step1, status: :unprocessable_entity
      return
    end

    session[:trip_params]["duration"] = params[:duration]

    if params[:from_confirm] == "true"
      redirect_to confirm_trips_path
    else
      redirect_to step2_trips_path
    end
  end

  def step2
    @budget = session.dig(:trip_params, "budget")&.to_i
  end

  def save_step2
    if params[:budget].blank?
      flash.now[:alert] = "予算を選択してください🐾"
      render :step2, status: :unprocessable_entity
      return
    end

    session[:trip_params]["budget"] = params[:budget].to_i

    if params[:from_confirm] == "true"
      redirect_to confirm_trips_path
    else
      redirect_to step3_trips_path
    end
  end

  def step3
    @departure = session.dig(:trip_params, "departure")
  end

  def save_step3
    if params[:departure].blank?
      flash.now[:alert] = "出発地を選択してください🐾"
      render :step3, status: :unprocessable_entity
      return
    end

    session[:trip_params]["departure"] = params[:departure]

    if params[:from_confirm] == "true"
      redirect_to confirm_trips_path
    else
      redirect_to step4_trips_path
    end
  end

  def step4
    @transport = session.dig(:trip_params, "transport")
  end

  def save_step4
    if params[:transport].blank?
      flash.now[:alert] = "交通手段を選択してください🐾"
      render :step4, status: :unprocessable_entity
      return
    end

    session[:trip_params]["transport"] = params[:transport]

    if params[:from_confirm] == "true"
      redirect_to confirm_trips_path
    else
      redirect_to step5_trips_path
    end
  end

  def step5
    @companion = session.dig(:trip_params, "companion")
  end

  def save_step5
    if params[:companion].blank?
      flash.now[:alert] = "同行者を選択してください🐾"
      render :step5, status: :unprocessable_entity
      return
    end

    session[:trip_params]["companion"] = params[:companion]

    redirect_to confirm_trips_path
  end

  def confirm
    @trip_params = session[:trip_params] || {}
    @duration  = @trip_params["duration"]
    @budget    = @trip_params["budget"]&.to_i
    @departure = @trip_params["departure"]
    @transport = @trip_params["transport"]
    @companion = @trip_params["companion"]
  end

  def create
    plans = cached_plans
    index = Integer(params[:plan_index], exception: false)
    plan = plans && index && index >= 0 ? plans[index] : nil

    if plan.blank? || session[:trip_params].blank?
      redirect_to root_path, alert: "提案の有効期限が切れました。もう一度条件を入力してください。"
      return
    end

    trip = build_and_save_trip!(plan, session[:trip_params])
    redirect_to trip_path(trip), notice: "旅のしおりを作成しました！"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[TripsController#create] #{e.message}")
    redirect_to proposals_path, alert: "しおりの作成に失敗しました。もう一度お試しください。"
  end

  def show
    @trip = Trip.includes(:schedules).find_by!(share_token: params[:share_token])
  end

  private

  def initialize_trip_session
    session[:trip_params] ||= {}
  end

  def cached_plans
    token = session[:proposal_token]
    return nil if token.blank?

    Rails.cache.read("trip_proposals:#{token}")
  end

  def build_and_save_trip!(plan, trip_params)
    ActiveRecord::Base.transaction do
      trip = Trip.create!(
        duration: trip_params["duration"],
        budget: trip_params["budget"].to_i,
        departure: trip_params["departure"],
        transport: trip_params["transport"],
        companion: trip_params["companion"],
        title: plan["title"],
        prefecture: Trip.detect_prefecture(plan["area"]),
        area: plan["area"],
        travel_time: plan["travel_time"],
        description: plan["summary"],
        estimated_cost: extract_cost(plan["estimated_budget"])
      )

      Array(plan["spots"]).each do |spot|
        trip.schedules.create!(
          day_number: 1,
          start_time: spot["time"],
          place_name: spot["name"],
          category: spot["category"],
          estimated_cost: spot["estimated_cost"],
          content: spot["description"]
        )
      end

      trip
    end
  end

  def extract_cost(text)
    return nil if text.blank?

    # "約4,200円" や "約7,000〜10,000円" から先頭の数値（4200, 7000）を抽出
    digits = text.tr("０-９，", "0-9,").scan(/\d[\d,]*/).first
    digits&.delete(",")&.to_i
  end
end
