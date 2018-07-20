class Api::V1::UserFollowedController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create

    @followed = FollowedMessage.new(follow_params)
    message = Message.find_by(id: params[:message_id])

    if @followed.save
      render json: {message: 'followed'}
    else
      head 422
    end
  end

  private
  def follow_params
    params.permit(:user_id,
                  :message_id)
  end
end
