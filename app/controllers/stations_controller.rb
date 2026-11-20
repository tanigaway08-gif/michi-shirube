class StationsController < ApplicationController
  def nearest
    if params[:lat].blank? || params[:lng].blank?
      render json: { error: "位置情報が正しく取得できませんでした🐾" }, status: :bad_request
      return
    end

    result = GoogleMaps::NearestStationService.new(
      lat: params[:lat],
      lng: params[:lng]
    ).call

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { stations: result[:stations] }, status: :ok
    end
  end
end
