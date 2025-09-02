FactoryBot.define do
  factory :user do
    first_name { "Juan" }
    last_name { "Dela Cruz" }
    email { "dela_cruz.juan@gmail.com" }
    password { "password123" }
    password_confirmation { "password123" }
    time_zone { "Singapore" }
    current_address { "Taiwan" }
    contact_number { "+639151234567" }
    confirmed_at { Time.current }
  end
end
