Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "static_pages#home"
  get 'contact', to: 'static_pages#contact'
  get 'about', to: 'static_pages#about'
  get 'service', to: 'static_pages#service'
  get 'service_adaptation', to: 'static_pages#service_adaptation'
  get 'service_consalting', to: 'static_pages#service_consalting'
  get 'contact_quote_send', to: 'static_pages#contact_quote_send'
  
end
