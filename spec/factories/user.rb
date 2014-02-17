FactoryGirl.define do
  sequence(:email) {|n| "user#{n}@foobar.com"}
  sequence(:remember_token) {|n| "r#{rand(1..9999999)}#{n}"}

  factory :user do
    email
    remember_token

    uid "1234"
    after(:build) {|u| u.provider = "google"}

    latitude 37.777703
    longitude -122.416019
  end
end