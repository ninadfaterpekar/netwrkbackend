class Api::V1::NetworksController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def index
    post_code = params[:post_code]
    @network = Network.find_by(post_code: post_code)
    Facebook::FeedFetch.new(current_user, 1).perform
    Twitter::FeedFetch.new(current_user, 1).perform
    Instagram::FeedFetch.new(current_user, 1).perform
    if @network
      @network.current_user = current_user
      if User.from_network(@network.id).count >= 1 ||
         User.from_network(@network.id).find_by(id: current_user.id)
        render json: { network: @network }
      else
        render json: {
          message: 'Network not found',
          users: User.from_network(@network.id),
          count: User.from_network(@network.id).count
        }, status: 200
      end
    else
      render json: { message: 'Network not found' }, status: 200
    end
  end

  def create
    @network = Network.new(network_params)
    @network.users_count = 1
    if @network.save
      TemplatesMailer.connect_mail(current_user.email).deliver_now
      @network.users << current_user
      p ' LOAD FIRST POST ' * 100
      social = %w[facebook twitter instagram]
      social.each do |s|
        m = Message.by_user(current_user.id)
                   .by_social(s)
                   .sort_by_newest.first
        m.update_attributes(post_code: @network.post_code, network_id: @network.id, created_at: Time.current) if m.present?
      end
      render json: { network: @network, users: User.from_network(@network.id) }, status: 200
    else
      p '---'
      p @network.errors
      head 422
    end
  end

  def list
    cities = current_user.networks_cities.uniq
    cities.each { |city| city.current_user = current_user }
    render json: cities.uniq.as_json(
      methods: %i[city network_list], except: %i[google_place_id name id]
    )
  end

  private

  def network_params
    params.require(:network).permit(:post_code, :google_place_id)
  end
end
