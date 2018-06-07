class Api::V1::MembersController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def create
    network = Network.find_by(post_code: params[:post_code])
    if network.present?
      p ' LOAD FIRST POST ' * 300
      social = %w[facebook twitter instagram]
      social.each do |s|
        m = Message.by_user(current_user.id)
                   .by_social(s)
                   .sort_by_newest.first
        m.update_attributes(post_code: network.post_code, network_id: network.id, created_at: Time.current) if m.present?
      end

      network.networks_users.create(user_id: current_user.id, invitation_sent: true)
      TemplatesMailer.connect_mail(current_user.email).deliver_now
      render json: network
    else
      head 422
    end
  end
end
