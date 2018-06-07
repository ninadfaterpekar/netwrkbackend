# Like up and down
class Api::V1::UserLikesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def create
    @like = UserLike.by_message(params[:user_like][:message_id])
                    .by_user(current_user.id).first
    message = Message.find_by(id: params[:user_like][:message_id])
    if @like.present?
      @like.destroy
      message.likes_count -= 1
      unless message.owner.id == current_user.id # TODO: uncomment this
        message.points -= UserLike::POINTS
        message.owner.update_attributes(
          points_count: message.owner.points_count - UserLike::POINTS
        )
      end
      message.save
      render json: message
    else
      @like = UserLike.new(like_params)
      if @like.save
        message.likes_count += 1
        unless message.owner.id == current_user.id # TODO: uncomment this
          message.points += UserLike::POINTS
          message.owner.update_attributes(
            points_count: message.owner.points_count + UserLike::POINTS
          )
        end
        message.save
        render json: message
      else
        head 422
      end
    end
  end

  private

  def like_params
    params.require(:user_like).permit(:user_id,
                                      :message_id)
  end
end
