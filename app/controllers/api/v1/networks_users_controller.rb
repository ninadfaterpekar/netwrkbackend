class Api::V1::NetworksUsersController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def index
    @network = Network.find_by(post_code: params[:post_code])
    @network&.networks_users&.find_by(user_id: current_user.id)&.refresh_last_entrance_at
    if @network
      render json: {
        unique_users:
          @network.networks_users.where(connected: false)
                  .or(
                    @network.networks_users
                            .where(connected: true)
                            .where(['last_entrance_at > ?', 1.month.ago])
                  ).count,
        users: User.from_network(@network.id).order(points_count: :desc).as_json(
          methods: [:avatar_url]
        )
      }
    else
      head 204
    end
  end

  def create
    user_from_network = NetworksUser.find_by(
      user_id: current_user.id,
      network_id: params[:network_id]
    )
    if user_from_network.nil?
      NetworksUser.create(
        user_id: current_user.id,
        network_id: params[:network_id],
        invitation_sent: true
      )
      render json: { message: 'connected' }, status: 200
    elsif user_from_network.connected
      user_from_network.update_attributes(connected: false)
      Message.where(
        network_id: params[:network_id],
        user_id: current_user.id,
        undercover: false # check dis
      ).destroy_all
      render json: { message: 'disconnected' }, status: 200
    else
      user_from_network.update_attributes(connected: true)
      render json: { message: 'connected' }, status: 200
    end
  end
end
