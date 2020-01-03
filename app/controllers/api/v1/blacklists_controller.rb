class Api::V1::BlacklistsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def index
    users = current_user.blacklist_users
    users.each { |user| user.current_user = current_user }
    render json: users.as_json(
      methods: %i[avatar_url blocked], except: %i[auth_token created_at]
    )
  end

  def create
    bl = Blacklist.find_by(user_id: current_user.id, target_id: params[:target_id])
    if bl.nil?
      Blacklist.create(user_id: current_user.id, target_id: params[:target_id])
      user = User.find_by(id: params[:target_id])
      user.points_count -= 15
      user.save
      render json: { message: 'block_ok' }, status: 200
    else
      bl.destroy
      user = User.find_by(id: params[:target_id])
      user.points_count += 15
      user.save
      render json: { message: 'unblock_ok' }, status: 200
    end
  end
end
