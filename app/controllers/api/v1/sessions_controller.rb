# Login Api Part
class Api::V1::SessionsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :check_token, except: %i[invitation_check check]

  def check
    render json: { messages: 'ok' }, status: 200
  end

  def create
    user_password = params[:user][:password]
    user_login = params[:user][:login]
    user_login.downcase!
    user = user_login.present? && User.where(
      'email = ? OR phone = ?', user_login, user_login
    ).first
    if user && user.valid_password?(user_password)
      sign_in user, store: false
      user.generate_authentication_token!
      user.save
      render json: user.as_json(
        methods: %i[avatar_url log_in_count fb_connected tou_accepted]
      ), status: 200
    else
      render json: { errors: 'Invalid login or password' }, status: 422
    end
  end

  def oauth_login
    user_id = params[:user][:provider_id]
    user_provider = params[:user][:provider_name]
    provider = user_id.present? && Provider.find_by(provider_id: user_id)
    if provider
      user = provider.user
      sign_in user, store: false
      user.generate_authentication_token!
      user.save
    else
      user = User.create!(oauth_params)
=begin if params[:user][:image_url].present?
  user.avatar = URI.parse(params[:user][:image_url])
end 
=end

      user.save
      user.providers << Provider.create(name: user_provider,
                                        token: params[:user][:token],
                                        provider_id: params[:user][:provider_id],
                                        secret: params[:secret])
    end
    render json: user.as_json(
      methods: %i[avatar_url log_in_count tou_accepted],
      except: %i[terms_of_use_accepted]
    ), status: 200
  end

  def verification
    message = Authentication::ChooseType.new(
      login: params[:login],
      country_code: params[:country_code]
    ).perform
    render json: message
  end

  def destroy
    user = User.find_by(auth_token: params[:id])
    user.generate_authentication_token!
    user.save
    head 204
  end

  private

  def oauth_params
    params.require(:user).permit(:first_name,
                                 :last_name,
                                 :email,
                                 :password,
                                 :phone,
                                 :provider_id,
                                 :provider_name)
  end
end
