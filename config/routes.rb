Rails.application.routes.draw do
  root 'static_pages#home'
  get  '/signup',   to: 'users#new'
  get    '/login',  to: 'sessions#new'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/edit-basic-info/:id', to: 'users#edit_basic_info', as: :basic_info
  patch 'update-basic-info',  to: 'users#update_basic_info'
  get 'users/:id/attendances/:date/edit', to: 'attendances#edit', as: :edit_attendances
  patch 'users/:id/attendances/:date/update', to: 'attendances#update', as: :update_attendances
  resources :users do
    resources :attendances, only: :create
    collection { post :import }
  end
  get    'users/:id/:designMode',  to: 'users#show', as: :user_show
  post   'month/:id/:month/apply',  to: 'users#monthApply', as: :month_apply
  post   'month/:id/approve',  to: 'users#monthApprove', as: :month_approve
  post   'zangyou/:id/apply',  to: 'users#zangyouApply', as: :zangyou_apply
  post   'zangyou/:id/approve',  to: 'users#zangyouApprove', as: :zangyou_approve
  post   'change/:id/:date/apply',  to: 'attendances#changeApply', as: :change_apply
  post   'change/:id/approve',  to: 'users#changeApprove', as: :change_approve
  get    'user/:id/:date/export', to: 'users#export', as: :csv_export
  get 'attend/users', to: 'users#working'
  get 'attendance/:id/log', to: 'attendance_log#index', as: :attendance_log
  resources :bases
end