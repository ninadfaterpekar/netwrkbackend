# Registration methods for API
class Api::V1::RegistrationsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token, :check_token

  def create
    resource = User.new(user_params)
    if resource.valid?
      resource.save
      render json: resource.as_json(
        methods: %i[log_in_count tou_accepted]
      ), status: 200
    else
      render json: resource.errors.messages, status: 422
    end
  end

  def update

    p resource = User.find_by(id: params[:id])

    if  params[:type] == 'login' && resource.sign_in_count == 1 ||
        params[:type] == 'update'
      resource.update(user_params)
      if resource.valid?
        resource.save

        render json: resource.as_json(
          methods: %i[avatar_url hero_avatar_url log_in_count tou_accepted is_password_set]
        ), status: 200
      else
        render json: resource.errors.messages, status: 422
      end
    else
      render json: resource.as_json(
        methods: %i[avatar_url hero_avatar_url log_in_count tou_accepted is_password_set]
      ), status: 200
    end
  end

  def check_login
    logins = User.all.pluck(params[:type].to_sym)
    if logins.include?(params[:login])
      head 422
    else
      render json: { message: 'ok' }, status: 200
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :name,
      :email,
      :password,
      :phone,
      :date_of_birthday,
      :invitation_sent,
      :avatar,
      :role_name,
      :role_description,
      :role_image_url,
      :hero_avatar,
      :gender,
      :points_count,
      :terms_of_use_accepted
    )
  end
end
