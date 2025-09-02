require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /dashboard" do
    it "shows dashboard" do
      get "/dashboard/index"
      expect(response).to have_http_status(:success)
    end
  end
end

# bundle exec rspec spec/requests/dashboard_spec.rb
