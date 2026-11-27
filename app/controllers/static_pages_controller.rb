class StaticPagesController < ApplicationController
def top
    @latest_trip = Trip.order(created_at: :desc).first
  end
end
