Forgepost::Application.routes.draw do
  get "/fpping" => "internal#ping"

  #namespace :usercp do
  #  resource :settings, :only => [:edit, :update]
  #end

  controller :products, :path => :product, :as => :products do
    get "/card" => :card_specials
  end

  controller :references, :path => :reference, :as => :references do
    get "/keywords" => :keywords
    get "/faction/:faction" => :faction, :as => :faction
    get "/rarities" => :rarities
    get "/mechanics" => :mechanics
  end

  controller :tooltips, :path => :tooltips, :as => :tooltips do
    get "/preview" => :preview
    get "/" => :show
  end

  controller :deckbuilders, :path => :deckbuilder, :as => :deckbuilder do
    get "/cards/:cachebust" => :cards, :as => :cards
    get "/storage" => :storage
    get "/deck-list" => :deck_list, :as => :deck_list

    delete "/" => :remove_deck
    post "/" => :save_deck

    get "/" => :index
  end

  controller :game_patches, :path => :patches, :as => :patches do
    get "/version-:version" => :show, :as => :show
    get "(/page-:page)" => :index, :defaults => {:page => "1"}
  end

  resources :sessions, :only => :new
  controller :sessions, :path => :sessions, :as => :session do
    get "/logout" => :destroy, :as => :logout
    get "/:provider/callback" => :create
    get "/failure" => :failure
  end

  #resources :faq, :only => :index

  get "/card/tt-ext/:card_id/:level.js" => "cards#ext_tooltip"

  controller :cards, :as => :cards do
    get "/card/tooltip/:card_id(/:cachebust)" => :tooltip, :as => :tooltip

    get "/card/:card_id/:name/version-:version" => :show_old, :as => :show_old
    get "/card/:card_id/:name/alt" => :show_alt, :as => :show_alt
    get "/card/:card_id/:name" => :show

    get "/cards/:factions/:rarities/:keywords/:category/:creature_type/lvl-:level(/atk-:min_atk-:max_atk)(/hp-:min_hp-:max_hp)(/set-:set)(/:sort_by-:sort_mode)/page-:page" => :index, :defaults => {:factions => "all", :rarities => "all", :keywords => "all", :category => "all", :min_hp => "", :max_hp => "", :min_atk => "", :max_atk => "", :creature_type => "any", :level => "1", :sort_by => "", :sort_mode => "", :page => "1", :set => "all"}
    get "/cards/:factions/:rarities/:keywords/:category/:creature_type/lvl-:level(/atk-:min_atk-:max_atk)(/hp-:min_hp-:max_hp)(/set-:set)(/:sort_by-:sort_mode)(/page-:page)" => :index, :as => :index_search, :defaults => {:factions => "all", :rarities => "all", :keywords => "all", :category => "all", :min_hp => "", :max_hp => "", :min_atk => "", :max_atk => "", :creature_type => "any", :level => "1", :sort_by => "", :sort_mode => "", :page => "1", :set => "all"}
    get "/cards" => :index, :as => :index, :defaults => {:factions => "all", :rarities => "all", :keywords => "any", :creature_type => "any", :category => "all", :level => "1", :min_hp => "", :max_hp => "", :min_atk => "", :max_atk => "", :sort_by => "", :sort_mode => "", :page => "1", :set => "all"}
  end

  controller :news, :path => "/news", :as => :news do
    get "(/page-:page)" => :index, :as => :index, :defaults => {:page => "1"}
    get "/page-:page" => :index
    get "/:slug" => :show, :as => :show
  end


  get "/privacy-policy" => "home#privacy_policy", :as => :privacy_policy
  get "/" => redirect("/cards", :status => 302), :as => :root

  unless Rails.env.production?
    match "/404" => "error#routing"
  end
end
