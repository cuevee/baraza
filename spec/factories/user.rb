# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :email do |n|
    "email#{n}@factory.com"
  end

  factory :user do |user|
    email
    password "Password1!"
    first_name "Patrick"
    last_name "Jane"
    type RegisteredUser.name
    confirmed_at Time.now
  end
end
