class Api::V1::LegendaryLikesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def create
    # if current_user.able_to_post_legendary?
    @like = LegendaryLike.by_message(params[:legendary][:message_id])
                         .by_user(current_user.id).first
    message = Message.find_by(id: params[:legendary][:message_id])
    if @like.present?
      render json: message.as_json(
          methods: %i[
            image_urls video_urls user text_with_links post_url locked
            expire_at has_expired timestamp is_synced
          ]
        )
    else
      @like = LegendaryLike.new(like_params)
      if @like.save # TODO: important: fix bags with multi threads
        if message.owner.id == current_user.id
          message.save
        else
          message.update_attributes(
            points: message.points + LegendaryLike::POINTS
          )
          current_user.update_attributes(legendary_at: DateTime.now)
          message.owner.update_attributes(
            points_count: message.owner.points_count + LegendaryLike::POINTS
          )
          #TemplatesMailer.legendary_mail(message.owner.email).deliver_now
        end
        render json: message.as_json(
          methods: %i[
            image_urls video_urls user text_with_links post_url locked
            expire_at has_expired timestamp is_synced
          ]
        )
      else
        head 422
      end
    end
    # else
    #   render json: {
    #     error: 'You cannot set messages as legendary so often'
    #   }, status: 422
    # end
  end

  def index
    render json: {
      able_to_post_legendary: current_user.able_to_post_legendary?
    }
  end

  private

  def like_params
    params.require(:legendary).permit(:user_id,
                                      :message_id)
  end
end
