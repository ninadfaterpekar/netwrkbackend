class Api::V1::BaseController < ApplicationController
  include Authenticable

  before_action :check_token, except: :devise_controller

  def check_token
    api_key = request.headers['Authorization']
    @user = User.by_auth_token(api_key).first if api_key

    unless @user
      head :unauthorized
      return false
    end
  end
end
