class Api::V1::ProfilesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_user, only: %i[show]

  def show
    if @user.present?
      @user.current_user = current_user
      render json: @user.as_json(
        methods: %i[
          avatar_url hero_avatar_url blocked
        ], except: %i[auth_token created_at encrypted_password]
      )
    else
      head 404
    end
  end

  def user_by_provider
    @provider = Provider.find_by(provider_id: params[:provider_id])
    if @provider.present?
      @provider.user.current_user = current_user
      render json: @provider.user.as_json(
        current_user: current_user.id,
        methods: %i[avatar_url hero_avatar_url blocked]
      )
    else
      head 204
    end
  end

  def connect_social
    providers = current_user.providers
    provider = providers.by_name(params[:user][:provider_name]).first
    if provider.present?
      provider.update(token: params[:user][:token],
                      provider_id: params[:user][:provider_id],
                      secret: params[:user][:secret])
    else
      providers << Provider.create(user_params)
    end
    render json: { message: 'ok' }, status: 200
  end

  def change_points_count # TODO: Change it
    # user = User.find_by(id: params[:user_id])
    # user.points_count += params[:points].to_i
    # user.save
    # render json: user
    render json: { message: 'Action is deprecated!' }, status: 204
  end

  def disabled_hero
    render json: { disabled: current_user.disabled_hero? }
  end

  def social_net_status
    social = Hash.new(false)
    current_user.providers.each { |provider| social[provider.name] = true }
    render json: social.as_json, status: 200
  end

  def accept_terms_of_use
    user = User.find_by(id: params[:id])
    if user
      user.update_attributes(terms_of_use_accepted: true, sign_in_count: 0)
      render json: { message: 'ok' }, status: 200
    else
      render json: { message: 'not found' }, status: 404
    end
  end

  def destroy
    if current_user.destroy
      render json: { message: 'ok' }, status: 200
    else
      render json: { message: 'not found' }, status: 404
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :provider_name,
      :token,
      :provider_id,
      :secret
    )
  end
end
