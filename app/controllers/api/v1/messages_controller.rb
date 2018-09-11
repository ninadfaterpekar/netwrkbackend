class Api::V1::MessagesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_room, only: %i[messages_from_room users_from_room]
  before_action :set_message, only: %i[
    update lock unlock destroy delete_for_all
  ]

  def index
    network = Network.find_by(post_code: params[:post_code])
    messages = []
    undercover_messages = []
    current_ids = []
    current_ids = params[:current_ids] if params[:current_ids].present?
    if params[:undercover] == 'true'
      #get messages from nearby area
      # On landing page display lines/network which are created from landing page or from area page (conversations)
      messages = Undercover::CheckDistance.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        params[:is_landing_page]
      ).perform

      #filter messages
      undercover_messages =
          Message.by_ids(messages.map(&:id))
              .by_not_deleted
              .without_blacklist(current_user)
              .without_deleted(current_user)
              .where(messageable_type: 'Network')
              .sort_by_last_messages(params[:limit], params[:offset])
              .with_images.with_videos
              .with_room(messages.map(&:id))
              .select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')

      undercover_messages, ids_to_remove =
          Messages::CurrentIdsPresent.new(
              current_ids: current_ids,
              undercover_messages: undercover_messages,
              with_network: network.present?,
              user: current_user,
              is_undercover: params[:undercover]
          ).perform
      render json: {
          messages: undercover_messages, ids_to_remove: ids_to_remove
      }
    elsif params[:undercover] == 'false'

=begin  
      messages = network.messages
          .by_not_deleted
          .undercover_is(false)
          .without_blacklist(current_user)
          .without_deleted(current_user)
          .where(messageable_type: 'Network')
          .sort_by_last_messages(params[:limit], params[:offset])
          .with_images.with_videos
=end

      #fetch area feed. Whats happening in that area.
      messages = Message.where(post_code:  params[:post_code])
                        .where("((messageable_type = 'Network' and undercover = false) or (messageable_type = 'Room' and undercover = true))")
                        .by_not_deleted
                        .without_blacklist(current_user)
                        .without_deleted(current_user)
                        .sort_by_last_messages(params[:limit], params[:offset])
                        .with_images.with_videos

      messages = messages.by_user(params[:user_id]) if params[:user_id].present?
      messages, _ids_to_remove =
        Messages::CurrentIdsPresent.new(
          current_ids: current_ids,
          undercover_messages: messages,
          with_network: network.present?,
          user: current_user,
          is_undercover: params[:undercover]
        ).perform
      render json: {
        messages: messages.as_json(
          methods: %i[
            image_urls video_urls like_by_user legendary_by_user user
            text_with_links post_url expire_at has_expired is_synced
          ]
        )
      }
    else
      message_list = undercover_messages + messages
      render json: {
        messages: message_list.as_json(
          methods: %i[
            image_urls video_urls like_by_user legendary_by_user user
            text_with_links post_url expire_at has_expired is_synced
          ]
        )
      }
    end
  end

  def nearby
    network = Network.find_by(post_code: params[:post_code])

    messages = []
    undercover_messages = []
    current_ids = []
    current_ids = params[:current_ids] if params[:current_ids].present?

    messages = Undercover::CheckDistance.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        false
      ).perform

      undercover_messages =
        Message.by_ids(messages.map(&:id))
               .by_not_deleted
               .without_blacklist(current_user)
               .without_deleted(current_user)
               .where(messageable_type: 'Network')
               .sort_by_points(params[:limit], params[:offset])
               .with_images
               .with_videos
               .with_room(messages.map(&:id))
               .select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')

      undercover_messages, ids_to_remove =
        Messages::CurrentIdsPresent.new(
          current_ids: current_ids,
          undercover_messages: undercover_messages,
          with_network: network.present?,
          user: current_user
        ).perform_nearby

      render json: {
        messages: undercover_messages, ids_to_remove: ids_to_remove
      }
  end

  def profile_messages
    user = User.find(params[:user_id])
    method = params[:public] == 'true'
    messages = MessageQuery.new(current_user).profile(
      user, params[:post_code], method, params[:limit], params[:offset]
    )
    render json: {
      messages: messages.as_json(
        methods: %i[
          image_urls video_urls like_by_user legendary_by_user user
          text_with_links post_url expire_at has_expired
        ]
      )
    }
  end

  def social_feed
    if params[:social].include?('facebook')
      Facebook::FeedFetch.new(current_user, 10).perform
    end
    if params[:social].include?('twitter')
      Twitter::FeedFetch.new(current_user, 10).perform
    end
    if params[:social].include?('instagram')
      Instagram::FeedFetch.new(current_user, 10).perform
    end
    messages = MessageQuery.new(current_user).from_socials(
      params[:limit], params[:offset], params[:social]
    )
    render json: {
      messages: messages.as_json(
        methods: %i[
          image_urls video_urls like_by_user legendary_by_user user
          text_with_links post_url expire_at has_expired
        ]
      )
    }
  end

  def create
    message = Message.new(
      message_params.merge(created_at: Time.at(params[:message][:timestamp].to_i))
    )
    message.messageable = Room.find(params[:room_id]) if params[:room_id].present?
    message.post_code = params[:post_code]
    begin
      message.expire_date = params[:message][:expire_date][:_d]
    rescue # bad request from app :(
    end
    if message.save
      Rooms::FindOrCreate.run(message: message)
      if params[:images].present?
        params[:images].each do |v|
          image = Image.create(image: v)
          message.images << image
        end
      end
      if params[:message][:video_urls].present?
        begin
          params[:message][:video_urls].each do |v|
            video = Video.create(thumbnail_url: v[:poster], url: v[:url])
            message.videos << video
          end
        end
      end
      if params[:message][:social_urls].present?
        params[:message][:social_urls].each do |i|
          image = Image.create(url: i)
          message.images << image
        end
      end
      if params[:message][:locked] == true
        message.make_locked(
          password: params[:message][:password],
          hint: params[:message][:hint]
        )
      end
      message.current_user = current_user
      channel =
        if message.messageable_type == 'Network'
          "messages#{params[:post_code]}chat"
        else
          "room_#{params[:room_id]}"
        end
      socket_type = ChatChannel::TYPE[:message] if params[:room_id].present?
      ActionCable.server.broadcast channel, socket_type: socket_type,
        message: message.as_json(
          methods: %i[
            image_urls locked video_urls user is_synced
            text_with_links post_url expire_at
            has_expired locked_by_user timestamp
          ]
        )

      render json: message.as_json(
        methods: %i[
          image_urls video_urls user text_with_links post_url locked
          expire_at has_expired locked_by_user timestamp is_synced
        ]
      )
    else
      head 422
    end
  end

  def update
    if @message
      @message.images << Image.new(image: params[:image])
      render json: @message.as_json(methods: [:image_urls])
    else
      head 422
    end
  end

  def lock
    if @message
      @message.make_locked(
        password: params[:password],
        hint: params[:hint]
      )
      render json: @message.as_json(methods: [:image_urls])
    else
      head 422
    end
  end

  def unlock
    if @message.present? && @message.correct_password?(params[:password])
      message_locked = LockedMessage.find_by(
        message_id: @message.id, user_id: current_user.id
      )
      if message_locked.present?
        message_locked.update_attributes(unlocked: true)
      end
      render json: @message.as_json(methods: [:image_urls])
    else
      head 422
    end
  end

  def legendary_list
    network = Network.find_by(id: params[:network_id])
    if network.present?
      messages = network.messages.legendary_messages
      render json: {
        messages: messages.as_json(
          methods: %i[
            image_urls video_urls like_by_user legendary_by_user user
            text_with_links post_url
          ]
        )
      }
    else
      head 204
    end
  end

  def sms_sharing
    params[:phone_numbers].each do |phone|
      Twilio::Connect.new(phone, params[:message]).perform
    end
    head 204
  end

  def delete
    @messages = Message.by_ids(params[:ids])
    if @messages
      @messages.each do |m|
        current_user.messages_deleted << m
      end
      head 204
    else
      head 422
    end
  end

  def block
    message = Message.find_by(id: params[:message_id])
    if message.present?
      message.update(points: message.points - 5)
      message.owner.update(points_count: message.owner.points_count - 5)
      current_user.messages_deleted << message
      head 204
    else
      head 422
    end
  end

  def update_message_points
    message = Message.find_by(id: params[:message_id])
    if message.present?
      message.update(points: message.points + params[:points])
      head 204
    else
      head 422
    end
  end

  # api/v1/messages/delete POST
  def delete_for_all
    @message.update_attributes(deleted: true)
    render json: { message: 'ok' }, status: 200
  end

  def messages_from_room
    unless @room
      return render json: { message: 'room isnt created' }, status: :bad_request
    end
    messages = @room.messages.order(created_at: :asc)
                    .offset(params[:offset]).limit(params[:limit])
    messages.each { |m| m.current_user = current_user }
    render json: { room_id: @room.id, messages: @room.messages.as_json(
      methods: %i[
        image_urls video_urls like_by_user legendary_by_user user
        text_with_links post_url expire_at has_expired is_synced
      ]
    ) }
  end

  def users_from_room
    unless @room
      return render json: { message: 'room isnt created' }, status: :bad_request
    end
    render json: {
      host_id: @room.owner.id,
      host_public: @room.message.public,
      users: @room.users.as_json(methods: %i[avatar_url])
    }
  end

  private

  def set_room
    @room = Room.find_by(message_id: params[:id])
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(
      :text,
      :is_emoji,
      :user_id,
      :lng,
      :lat,
      :social,
      :undercover,
      :room_id,
      :network_id,
      :public,
      :hint,
      :post_url,
      :expire_date,
      :role_name,
      :place_name
    )
  end
end
