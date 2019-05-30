class Api::V1::MessagesController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_room, only: %i[messages_from_room users_from_room]
  before_action :set_message, only: %i[
    update lock unlock destroy delete_for_all replies_on_message
  ]

  def index
    network = Network.find_by(post_code: params[:post_code])
    messages = []
    undercover_messages = []
    current_ids = []
    current_ids = params[:current_ids] if params[:current_ids].present?

    if params[:undercover] == 'true'
      # get messages from nearby area
      # On landing page display lines/network which are created from landing page or from area page (conversations)
      messages = Undercover::CheckDistance.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        params[:is_landing_page]
      ).perform

      messageIds = messages.map(&:id)

      if params[:is_landing_page] == 'true'
        # on landing page display followed messages + its nearby location messages
        followed_messages = FollowedMessage.where(user_id: current_user)

        followed_message_ids = followed_messages.map(&:message_id)

        own_messages = Message.where(user_id: current_user)
                              .where(messageable_type: 'Network')
                              .where(undercover: true)
                              .where(deleted: false)

        own_message_ids = own_messages.map(&:id)

        messageIds = messageIds + followed_message_ids + own_message_ids
        messageIds = messageIds.uniq
      end

      # filter messages
      # undercover_messages = Message.by_ids(messageIds)
      #                              .by_not_deleted
      #                              .without_blacklist(current_user)
      #                              .without_deleted(current_user)
      #                              .where(messageable_type: 'Network')
      #                              .where("(expire_date is null OR expire_date > :current_date)", {current_date: DateTime.now})
      #                              .sort_by_last_messages(params[:limit], params[:offset])
      #                              .with_images.with_videos
      #                              .with_room(messageIds)
      #                              .select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')


      # Fetch conversation + conversation message + Lines(own) + Lines(followed) + Lines(within distance even if not followed)
      # Do not show messages on Line at landing page
      undercover_messages = Message.by_ids(messageIds)
             .by_not_deleted
             .without_blacklist(current_user)
             .without_deleted(current_user)
             .where("(messageable_type = 'Network' OR (messageable_type = 'Room' and undercover = false))")
             .where("(expire_date is null OR expire_date > :current_date)", {current_date: DateTime.now})
             .sort_by_last_messages(params[:limit], params[:offset])
             .with_images.with_videos
             .left_joins(:room)
             .select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')
             
      undercover_messages, ids_to_remove = Messages::CurrentIdsPresent.new(
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

  
      # messages = network.messages
      #     .by_not_deleted
      #     .undercover_is(false)
      #     .without_blacklist(current_user)
      #     .without_deleted(current_user)
      #     .where(messageable_type: 'Network')
      #     .sort_by_last_messages(params[:limit], params[:offset])
      #     .with_images.with_videos


      # fetch area feed. Whats happening in that area.

      if params[:is_distance_check] == 'true'
        #if filter distance is on then messages from that postcode
        messages = Message.where(post_code:  params[:post_code])
                        .where("((messageable_type = 'Network') or (messageable_type = 'Room' and undercover = true))")
                        .by_not_deleted
                        .without_blacklist(current_user)
                        .without_deleted(current_user)
                        .sort_by_last_messages(params[:limit], params[:offset])
                        .with_images.with_videos

      else
        # fetch all messages if distance check if off
        messages = Message.where("((messageable_type = 'Network') or (messageable_type = 'Room' and undercover = true))")
                        .by_not_deleted
                        .without_blacklist(current_user)
                        .without_deleted(current_user)
                        .sort_by_last_messages(params[:limit], params[:offset])
                        .include_room
                        .with_images.with_videos
      end

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
        messages: messages, ids_to_remove: _ids_to_remove
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


  # Get near by lines from latitude and longitude 
  # Current radius is 15 miles
  def nearby_search
    messages = []
    undercover_messages = []
    current_ids = []
    current_ids = params[:current_ids] if params[:current_ids].present?
    
    network = Network.find_by(post_code: params[:post_code])

    messages = Undercover::CheckNear.new(
      params[:post_code],
      params[:lng],
      params[:lat],
      current_user
    ).perform

    if params[:message_type] && params[:message_type] != ''
      undercover_messages =
        Message.by_ids(messages.map(&:id))
               .by_not_deleted
               .without_blacklist(current_user)
               .without_deleted(current_user)
               .where(messageable_type: 'Network')
               .where(message_type: params[:message_type])
               .sort_by_points(params[:limit], params[:offset])
    else
      undercover_messages =
        Message.by_ids(messages.map(&:id))
               .by_not_deleted
               .without_blacklist(current_user)
               .without_deleted(current_user)
               .where(messageable_type: 'Network')
               .sort_by_points(params[:limit], params[:offset])
    end

    render json: {
      messages: undercover_messages.as_json(
        methods: %i[
          image_urls video_urls text_with_links user expire_at has_expired
        ]
      )
    }
  end


  def nearby
    network = Network.find_by(post_code: params[:post_code])

    messages = []
    undercover_messages = []
    current_ids = []
    current_ids = params[:current_ids] if params[:current_ids].present?

=begin    
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
               .with_room(messages.map(&:id))
               .select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')
=end
      if params[:is_distance_check] == 'true'
         
         messages = Undercover::CheckNear.new(
          params[:post_code],
          params[:lng],
          params[:lat],
          current_user
        ).perform

        undercover_messages = Message.select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')
               .by_ids(messages.map(&:id))
               .by_not_deleted
               .without_blacklist(current_user)
               .without_deleted(current_user)
               .where(messageable_type: 'Network')
               .where(undercover: true)
               .where(post_code: params[:post_code])
               .where.not(user_id: current_user)
               .where("(expire_date is null OR expire_date > :current_date)", {current_date: DateTime.now})
               .joins("INNER JOIN Rooms ON Rooms.message_id = Messages.id AND Messages.messageable_type = 'Network'")
               .sort_by_points(params[:limit], params[:offset])
      else
        undercover_messages =
          Message.select('Messages.*, Rooms.id as room_id, Rooms.users_count as users_count')
                 .by_not_deleted
                 .without_blacklist(current_user)
                 .without_deleted(current_user)
                 .where(messageable_type: 'Network')
                 .where(undercover: true)
                 .where.not(user_id: current_user)
                 .where("(expire_date is null OR expire_date > :current_date)", {current_date: DateTime.now})
                 .joins("INNER JOIN Rooms ON Rooms.message_id = Messages.id AND Messages.messageable_type = 'Network'")
                 .sort_by_points(params[:limit], params[:offset])  
      end

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
    #if message id is present then update message
    if params[:message][:messageId]
      #if message_id set then edit the message
      message = Message.find(params[:message][:messageId]) 

      message.update(
         message_params.merge(updated_at: Time.at(params[:message][:timestamp].to_i)) 
      )

      message.current_user = current_user

      if params[:message][:locked] == false
        #make message unlocked 
        message.make_unlocked(
            password: params[:message][:password],
            hint: params[:message][:hint]
          )
      elsif params[:message][:locked] == true
        #make message locked 
        message.make_locked(
            password: params[:message][:password],
            hint: params[:message][:hint]
          )
      end

      render json: message.as_json(
      methods: %i[
          image_urls video_urls user text_with_links post_url locked
          expire_at has_expired locked_by_user timestamp is_synced
        ]
      )
    else
      #if message id not present then create message
      message = Message.new( 
        message_params.merge(created_at: Time.at(params[:message][:timestamp].to_i)) 
      )

      message.messageable = Room.find(params[:room_id]) if params[:room_id].present?

      # If message is reply of other message then create reply
      if params[:reply_to_message_id].present?
        replyToMessage = Message.find(params[:reply_to_message_id])
        reply = Reply.new(message: replyToMessage, user_id: current_user.id)
       
        if reply.save
          message.messageable = reply
        end
      end

      begin
        message.expire_date = params[:message][:expire_date][:_d]
      rescue # bad request from app :(
      end
      message.post_code = params[:post_code]

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
          #Owner have access by default to its own private lines. 
          LockedMessage.find_or_create_by(user_id: current_user.id, message_id: message.id, unlocked: true)
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
    if @message.present? && params[:password].present? && @message.correct_password?(params[:password])
      message_locked = LockedMessage.find_by(
        message_id: @message.id, user_id: current_user.id
      )

      p message_locked
      if message_locked.present?
        message_locked.update_attributes(unlocked: true)
      end
      render json: @message.as_json(methods: [:image_urls])
    elsif @message.present? && @message.user_id == current_user.id
      #if current user is message owner, then he can unlock message for other users
      user_id = params[:message][:user_id]
      message_locked = LockedMessage.find_by(
        message_id: @message.id, user_id: user_id
      )

      if message_locked.present?
        if params[:status] == 'ACCEPT'
          message_locked.update_attributes(unlocked: true)
        end
        requested_message = Message.find_by(id: params[:message][:id])
        #delete requested message
        requested_message.update_attributes(deleted: true)
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
    messages = @room.messages.order(created_at: :desc)
                    .offset(params[:offset]).limit(params[:limit])
    messages.each { |m| m.current_user = current_user }
    render json: { room_id: @room.id, messages: messages.as_json(
      methods: %i[
        image_urls video_urls like_by_user legendary_by_user user
        text_with_links post_url expire_at has_expired is_synced
      ]
    ) }
  end

  def replies_on_message
    unless @message
      return render json: { message: 'message isnt created' }, status: :bad_request
    end

    replies = @message.replies
    messages = Message.by_messageable(replies.map(&:id), 'Reply')
               .by_not_deleted
               .sort_by_last_messages_id(params[:limit], params[:offset])
    
    messages.each { |m| m.current_user = current_user }
    render json: { reply_to_message_id: @message.id, messages: messages.as_json(
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

  def send_notifications
    
    notification_type = params[:notification_type]

    if params[:messageable_type] == 'Room'
      
      # notification title should be line name
      room = Room.find(params[:messageable_id])
      message = Message.find(room.message_id)

      if notification_type == 'like'
        # when someone likes message then send notification to its owner
        notification_title = message.title
        notification_body = "Looks like you’ve put some good stuff out there"

        followed_users = User.where(id:  params[:user_id])
        user_registration_ids = followed_users.map(&:registration_id).compact

      elsif notification_type == "legendary" 
        # when user pin message then send notification to its owner
        notification_title = message.title
        notification_body = "You've become a legend"

        followed_users = User.where(id:  params[:user_id])
        user_registration_ids = followed_users.map(&:registration_id).compact

      elsif notification_type == "new_message"

        notification_title = message.title
        notification_body = params[:text]

        followed_messages = FollowedMessage.where(message_id: message.id)
        followed_message_userIds = followed_messages.map(&:user_id)

        room_users = RoomsUser.where(room_id: room.id)
        room_userIds = room_users.map(&:user_id)

        #send notification to message owner + followers users + connected users to line
        final_usersIds = followed_message_userIds + room_userIds + [message.user_id]
        final_usersIds = final_usersIds.uniq

        final_usersIds.delete(current_user.id)

        followed_users = User.where(id: final_usersIds)
        user_registration_ids = followed_users.map(&:registration_id).compact
      end 
    elsif params[:messageable_type] == 'Network'
      if notification_type == 'legendary'
        #when user pin message then send notification to its owner
        notification_title = params[:title]
        notification_body = "You've become a legend"

        followed_users = User.where(id: params[:user_id])
        user_registration_ids = followed_users.map(&:registration_id).compact
      end
    elsif params[:messageable_type] == 'Reply'
      if notification_type == "new_reply"

        reply = Reply.find_by(id: params[:messageable_id])
        message = Message.find_by(id: reply.message.id)
        replies = Reply.where(message_id: reply.message.id)
        
        replied_userIds = replies.map(&:user_id)

        #send notification to message owner + users who replied to that message 
        
        final_usersIds = replied_userIds + [message.user_id]
        final_usersIds = final_usersIds.uniq.compact

        final_usersIds.delete(current_user.id)

        users = User.where(id: final_usersIds)
        user_registration_ids = users.map(&:registration_id).compact

        #when user reply on message then send notification to its owner
        notification_title = "You've new reply" 
        notification_body = message.title
      end
    end   

    if user_registration_ids.length > 0
      notifications_result = Notifications::Push.new(
          current_user,
          notification_title,
          notification_body,
          user_registration_ids,
          params
        ).perform
    end

    render json: {
      status: true,
      notification_type: notification_type,
      notification_title: notification_title,
      notification_body: notification_body,
      params: params
    }
  end

  def show
    message = Message.find(params[:id])
    
    if message 
      render json: {
        message: message.as_json(
          methods: %i[
                      image_urls video_urls like_by_user legendary_by_user user
                      text_with_links post_url expire_at has_expired is_synced
                    ]
        )
      }, status: 200
    else
      render json: {
        message: []
      }, status: :bad_request
    end
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
      :title,
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
      :place_name,
      :message_type
    )
  end
end
