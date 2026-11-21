# frozen_string_literal: true

class TripProposalsController < ApplicationController
  before_action :load_plans, only: %i[index show]

  def create
    conditions = trip_conditions
    if conditions.values.any?(&:blank?)
      redirect_to root_path, alert: "旅行の条件を最初から入力してください。"
      return
    end

    result = Openai::TripPlannerService.new(
      duration: conditions[:duration],
      budget: conditions[:budget],
      departure: conditions[:departure],
      transport: conditions[:transport],
      companion: conditions[:companion]
    ).call

    token = SecureRandom.uuid
    Rails.cache.write(cache_key(token), result["plans"], expires_in: 1.hour)
    session[:proposal_token] = token

    redirect_to proposals_path
  rescue Openai::TripPlannerService::Error => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  def index; end

  def show
    index = Integer(params[:id], exception: false)
    @plan = index && index >= 0 ? @plans[index] : nil
    @plan_index = index

    return if @plan.present?

    redirect_to proposals_path, alert: "指定されたプランが見つかりませんでした。"
  end

  private

  def load_plans
    token = session[:proposal_token]
    @plans = token.present? ? Rails.cache.read(cache_key(token)) : nil

    return if @plans.present?

    redirect_to root_path, alert: "提案の有効期限が切れました。もう一度条件を入力してください。"
  end

  def cache_key(token)
    "trip_proposals:#{token}"
  end

  def trip_conditions
    trip_params = session[:trip_params] || {}
    {
      duration: trip_params["duration"],
      budget: trip_params["budget"]&.to_i,
      departure: trip_params["departure"],
      transport: trip_params["transport"],
      companion: trip_params["companion"]
    }
  end
end
