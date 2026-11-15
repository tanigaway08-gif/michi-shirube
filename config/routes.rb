Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#top"

  resources :trips do
    collection do
      get  :step1
      post :save_step1
      get  :step2
      post :save_step2
      get  :step3
      post :save_step3
      get  :step4
      post :save_step4
      get  :step5
      post :save_step5
      get  :confirm
      post :propose # AI提案処理などのアクションがあれば追加
    end
  end
end
