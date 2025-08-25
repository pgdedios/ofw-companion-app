require 'rails_helper'

RSpec.describe "RemittanceCenters", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/remittance_centers/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/remittance_centers/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end
