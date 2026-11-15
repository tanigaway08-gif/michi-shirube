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

  private

  def initialize_trip_session
    session[:trip_params] ||= {}
  end
end
