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
      if params[:is_distance_check] == 'true'
        nearby
      else
        get_landing_page_feeds(network, current_ids)
      end
    elsif params[:undercover] == 'false'
      get_public_area_page_feeds(network, current_ids)
    else
      message_list = undercover_messages + messages
      render json: {
        messages: message_list.as_json(
          methods: %i[
            users_count, avatar_url image_urls video_urls like_by_user legendary_by_user user
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
    mutual_communities_ids = []
    undercover_messages = []
    current_ids = []
    current_ids = params[:current_ids] if params[:current_ids].present?
    
    # network = Network.find_by(post_code: params[:post_code])

    messages = Undercover::CheckNear.new(
      params[:post_code],
      params[:lng],
      params[:lat],
      current_user,
      messages
    ).perform

    message_ids = messages.map(&:id)

    # If user is connected then show mutual public and private communities but avoid showing semi public communities
    # As it can directly accessible though it is private and without password
    # If user not connected then show mutual public communities.
    if params[:with_mutual_connected_communities] && params[:with_mutual_connected_communities] == 'true'
      # find the connected users of community
      community = Message.find(params[:message_id])
      connected_user_ids = community.room.rooms_users.map(&:user_id)
      mutual_rooms_ids = RoomsUser.where(user_id: connected_user_ids).map(&:room_id)

      room_message_ids = Room.where(id: mutual_rooms_ids).map(&:message_id)
      if message_ids.count > 0
        if params[:is_connected] == 'true'
          # get public, private (avoid semi public) communities of connected users + get nearby all public and private communities
          mutual_communities = Message.by_messageable_type('Network')
                                   .by_ids(room_message_ids)
                                   .by_not_deleted
                                   .where("message_type is null or message_type = 'CUSTOM_LOCATION' or message_type = 'NONCUSTOM_LOCATION'")
                                   .where.not('(public = false and locked = false)')

          mutual_communities_ids = mutual_communities.map(&:id)

          message_ids = messages.map(&:id)
          message_ids = message_ids + mutual_communities_ids
        else
          # get public (avoid semi public) communities of connected users + get nearby public communities
          mutual_communities = Message.by_messageable_type('Network')
                                   .by_ids(room_message_ids)
                                   .by_not_deleted
                                   .where("message_type is null or message_type = 'CUSTOM_LOCATION' or message_type = 'NONCUSTOM_LOCATION'")
                                   .where('public = true')

          mutual_communities_ids = mutual_communities.map(&:id)

          nearby_public_messages = Message.by_ids(message_ids)
                                       .where.not('(public = false)')

          message_ids = nearby_public_messages.map(&:id)
          message_ids = message_ids + mutual_communities_ids
        end
      end
    end

    message_ids = message_ids.uniq

    if params[:message_type] && params[:message_type] != ''
      undercover_messages =
          Message.by_ids(message_ids)
              .by_not_deleted
              .without_blacklist(current_user)
              .without_deleted(current_user)
              .where(messageable_type: 'Network')
              .where(message_type: params[:message_type])
              .where.not('(public = false and locked = false)')
              .sort_by_points(params[:limit], params[:offset])
    else
      undercover_messages =
          Message.by_ids(message_ids)
              .by_not_deleted
              .without_blacklist(current_user)
              .without_deleted(current_user)
              .where(messageable_type: 'Network')
              .where.not('(public = false and locked = false)')
              .sort_by_points(params[:limit], params[:offset])
    end

    undercover_messages.each { |message| message.current_user = current_user }

    render json: {
      messages: undercover_messages.as_json(
        methods: %i[
          avatar_url image_urls video_urls like_by_user legendary_by_user user is_synced
            text_with_links post_url expire_at has_expired is_connected locked_by_user is_followed line_locked_by_user
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

    messages = Undercover::CheckNear.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        messages
    ).perform

    messageIds = messages.map(&:id)
    messages.each { |message|
      if message.public == false && message.locked == false
        messageIds.delete(message.id)
      end
    }

    undercover_messages = Message
                              .by_ids(messageIds)
                              .include_room
                              .by_not_deleted
                              .without_blacklist(current_user)
                              .without_deleted(current_user)
                              .with_images
                              .with_videos
                              .with_non_custom_lines
                              .with_messageble
                              .by_messageable_type('Network')
                              .where("(message_type = 'CUSTOM_LOCATION' OR message_type IS NULL)")
                              .where(undercover: true)
                              .where.not(user_id: current_user)
                              .where("
                                  ((expire_date IS NULL OR expire_date > :current_date) and (message_type != 'LOCAL_MESSAGE' OR message_type is null))
                                ",
                                {
                                  current_date: DateTime.now
                                })
                              .sort_by_last_messages(params[:limit], params[:offset])

    undercover_messages, ids_to_remove =
        Messages::CurrentIdsPresent.new(
            current_ids: current_ids,
            undercover_messages: undercover_messages,
            with_network: network.present?,
            user: current_user
        ).perform

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

    own_communities_count = Message.by_user(current_user.id)
                                  .where("messageable_type = 'Network' AND (message_type is null or message_type = 'CUSTOM_LOCATION' or message_type = 'NONCUSTOM_LOCATION')")
                                  .count

    own_local_messages_count = Message.by_user(current_user.id)
                                  .where("messageable_type = 'Network' AND message_type = 'LOCAL_MESSAGE'")
                                  .count

    primary_community = Message.by_user(current_user.id)
                                  .where("public = true  OR (public = false AND locked = true)")
                                  .where("messageable_type = 'Network' AND (message_type is null or message_type = 'CUSTOM_LOCATION' or message_type = 'NONCUSTOM_LOCATION')")
                                  .order(id: :asc)
                                  .offset(0)
                                  .limit(1)

    if primary_community.count > 0
      primary_community_id = primary_community[0].id
    else
      primary_community_id = nil
    end

    render json: {
      messages: messages.as_json(
        methods: %i[
          avatar_url image_urls video_urls like_by_user legendary_by_user user
          text_with_links post_url expire_at has_expired
        ]
      ),
      metadata: [
          local_messages_count: own_local_messages_count,
          communities_count: own_communities_count,
          user_points_count: user.points_count,
          primary_community_id: primary_community_id
      ]
    }
  end

  # Get profile near by private message within 15 miles
  def nearby_profile_messages
    user_id = params[:user_id]

    messages = Message.by_messageable_type('Network')
            .locked_is(true)
            .by_user(user_id)
            .by_not_deleted
            .sort_by_last_messages(params[:limit], params[:offset])

    #if user have private message then only filter with 15 miles
    if messages.count > 0 && params[:is_distance_check] == 'true'
      # check does messages are within 15 miles
      messages = Undercover::CheckNear.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        messages
      ).perform
    end

    render json: {
      messages: messages.as_json(
        methods: %i[
          avatar_url image_urls video_urls user
          text_with_links post_url expire_at has_expired line_locked_by_user
        ]
      )
    }
  end

  # Get the profile own and followed lines but not get conversations (messageble_type = 'Network' && undercover = false)
  def profile_communities
    messages = MessageQuery.new(current_user).communities(
      params[:limit], params[:offset]
    )

    render json: {
      messages: messages.as_json(
        methods: %i[
          avatar_url image_urls video_urls like_by_user legendary_by_user user
          text_with_links post_url expire_at has_expired
        ]
      )
    }, status: 200
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

  def share
    send_messages = []
    community_member_ids = []
    if params[:message_ids]
      # Get the room ids from message ids / network ids
      rooms = Room.where(message_id: params[:message_ids])
      room_ids = rooms.map(&:id)

      rooms.each { |room|
        message = Message.new(
            message_params.merge(
                created_at: Time.at(params[:message][:timestamp].to_i),
                updated_at: Time.at(params[:message][:timestamp].to_i)
            )
        )

        message.messageable = Room.find(room.id)
        begin
          message.expire_date = params[:message][:expire_date][:_d]
        rescue # bad request from app :(
        end

        message.post_code = params[:post_code]
        if message.save
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
          ActionCable.server.broadcast channel,
                                       socket_type: socket_type,
                                       message: message.as_json(
                                         methods: %i[
                                              image_urls locked video_urls user is_synced
                                              text_with_links post_url expire_at
                                              has_expired locked_by_user timestamp
                                          ]
                                       )

          send_messages.push(message)
        end

        # Auto follow room_users for that conversation id.
        if params[:message][:conversation_line_id].present?
          if room.users.count > 0
            room.users.each {|room_user|
              community_member_ids.push(room_user.id)
              FollowedMessage.find_or_create_by(user_id: room_user.id, message_id: params[:message][:conversation_line_id])
            }
          end
        end
      }

      # send notification to connected community members.
      # exclude local message owner
      community_member_ids.uniq.compact
      community_member_ids.delete(current_user.id)

      users = User.where(id: community_member_ids)
      user_registration_ids = users.map(&:registration_id).compact

      # when user reply on message then send notification to its owner
      notification_title = current_user.name
      notification_body = params[:message][:title] << '?'

      # send id as conversation live id
      params[:message][:id] = params[:message][:conversation_line_id]
      if user_registration_ids.length > 0
        notifications_result = Notifications::Push.new(
            current_user,
            notification_title,
            notification_body,
            user_registration_ids,
            params[:message]
        ).perform
      end

      render json: {
          notification_title: notification_title,
          notification_body: notification_body,
          community_member_ids: community_member_ids,
          send_messages: send_messages
      }
    else
      render json: {
          error: true,
          message: 'Message ids not set'
      }
    end
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
          avatar_url image_urls video_urls user text_with_links post_url locked
          expire_at has_expired locked_by_user timestamp is_synced
        ]
      )
    else
      #if message id not present then create message
      message = Message.new( 
        message_params.merge(
            created_at: Time.at(params[:message][:timestamp].to_i),
            updated_at: Time.at(params[:message][:timestamp].to_i)
        )
      )

      room = Room.find(params[:room_id]) if params[:room_id].present?
      if room.present?
        message.messageable = room if room.present?
        line_message = room.message.update_attributes(updated_at: DateTime.now)
      end

      #if conversation is rejected then unfollow to that conversation, So on landing page this feed will not display.
      if (params[:message][:message_type] == "CONV_REJECTED")
        FollowedMessage.where(
            user_id: current_user.id,
            message_id: params[:message][:conversation_line_id]
        ).delete_all
      end

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
            avatar_url image_urls video_urls user text_with_links post_url locked
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
      if params[:is_distance_check] == 'true'
        # Local
        # fetch Lines and Line messages of that area (zipcode of passed networkId) which are set as legendary by any user
        messages = Message.by_not_deleted.
            by_post_code(network.post_code).
            joins_legendary_messages.
            sort_by_points(params[:limit], params[:offset])
      else
        # World
        # Show all legendary posts on world
        messages = Message.by_not_deleted.
            joins_legendary_messages.
            sort_by_points(params[:limit], params[:offset])
      end

      messages = Message.by_ids(messages.map(&:id))

      messages.each do |message|
        message.current_user = current_user
      end

      #messages = network.messages.legendary_messages
      render json: {
        messages: messages.as_json(
          methods: %i[
            avatar_url image_urls video_urls like_by_user legendary_by_user user
            text_with_links post_url is_followed is_connected line_locked_by_user
            line_message_type
          ]
        )
      }
    else
      render json: {
          messages:[],
          message: "Network not found"
      }
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

  def update_message_avatar
    message = Message.find_by(id: params[:message][:id])
    if message.present?
      message.update(message_params)
      message.save

      render json: message.as_json(
          methods: %i[
            avatar_url like_by_user user is_synced
            text_with_links post_url expire_at has_expired
          ]
        ), status: 200
    else
        p 'Error in uploading'
        head 422
    end
  end

  # api/v1/messages/delete POST
  def delete_for_all
    #delete the line
    @message.update_attributes(deleted: true)

    #delete associated messages on lines
    messages = Message.where(messageable: @message.room)
    messages.update_all(deleted: true) if messages.present?

    # if message is conversation line / means message_type is 'LOCAL_MESSAGE' then delete the associated requests
    conversation_line_requests = @message.conversation_line_messages.update_all(deleted: true) if @message.message_type == 'LOCAL_MESSAGE'

    render json: { message: 'ok' }, status: 200
  end

  def messages_from_room
    unless @room
      return render json: { message: 'room isnt created' }, status: :bad_request
    end
    messages = Message.where(messageable: @room)
                     .by_not_deleted
                     .order(created_at: :desc)
                     .offset(params[:offset]).limit(params[:limit])

    messages.each { |m|
      m.current_user = current_user
    }

    render json: { room_id: @room.id, messages: messages.as_json(
      methods: %i[
        avatar_url image_urls video_urls like_by_user legendary_by_user user
        text_with_links post_url expire_at has_expired is_synced conversation_status
        is_connected line_message_type
      ],
      include: [
          conversation_line: {
              only: [
                  :id,
                  :text
              ],
              include: [
                  room: {
                      only: [
                          :id,
                          :message_id,
                          :users_count,
                      ],
                      include: [
                          rooms_users: {
                              methods: [
                                  :user
                              ],
                              only: [
                                  :id,
                                  :room_id,
                                  :user_id,
                                  :read,
                                  :unread_count
                              ]
                          }
                      ]
                  }
              ]

          }
      ])
    }
  end

  def replies_on_message
    unless @message
      return render json: { message: 'message isnt created' }, status: :bad_request
    end

    replies = @message.replies
    messages = Message.by_messageable(replies.map(&:id), 'Reply')
               .by_not_deleted
               .order(id: :asc)
               .limit(params[:limit])
               .offset(params[:offset])
    
    messages.each { |m| m.current_user = current_user }
    render json: { reply_to_message_id: @message.id, messages: messages.as_json(
      methods: %i[
        avatar_url image_urls video_urls like_by_user legendary_by_user user
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

        followed_users = User.where(id: params[:user_id])
        user_registration_ids = followed_users.map(&:registration_id).compact

      elsif notification_type == "new_message"

        if params[:message_type] == 'CONV_REJECTED'
          # Notify conversation owner when conversation is rejected by user.
          notification_title = message.title
          notification_body = params[:text]

          followed_users = User.where(id: message.user_id)
          user_registration_ids = followed_users.map(&:registration_id).compact
        elsif params[:message_type] == 'CONV_ACCEPTED'
          # Notify conversation owner + connected users of conversation when conversation is accepted by any user.
          notification_title = params[:user][:name]
          notification_body = message.title + ' - ' + params[:user][:name] + ' is in'

          room_users = RoomsUser.where(room_id: room.id)
          room_userIds = room_users.map(&:user_id)

          final_usersIds = room_userIds + [message.user_id]
          final_usersIds = final_usersIds.uniq

          followed_users = User.where(id: final_usersIds)
          user_registration_ids = followed_users.map(&:registration_id).compact

          params['id'] = message.conversation_line_id # change the parent id. so it will open LM when click on notification
        else
          # When undercover = false means local message, then dont include followed users as they may not be connected to resolve freeze issue
          notification_title = params[:user][:name]
          notification_body = params[:text]

          if params[:undercover] == false
            room_users = RoomsUser.where(room_id: room.id)
            room_userIds = room_users.map(&:user_id)

            #send notification to message owner + connected users to line
            final_usersIds = room_userIds + [message.user_id]
            final_usersIds = final_usersIds.uniq
          else
            followed_messages = FollowedMessage.where(message_id: message.id)
            followed_message_userIds = followed_messages.map(&:user_id)

            room_users = RoomsUser.where(room_id: room.id)
            room_userIds = room_users.map(&:user_id)

            #send notification to message owner + followers users + connected users to line
            final_usersIds = followed_message_userIds + room_userIds + [message.user_id]
            final_usersIds = final_usersIds.uniq
          end

          final_usersIds.delete(current_user.id)

          followed_users = User.where(id: final_usersIds)
          user_registration_ids = followed_users.map(&:registration_id).compact
        end
      end 
    elsif params[:messageable_type] == 'Network'
      if notification_type == 'like'

        #when user pin message then send notification to its owner
        notification_title = params[:title]
        notification_body = "Looks like you’ve put some good stuff out there"

        followed_users = User.where(id: params[:user_id])
        user_registration_ids = followed_users.map(&:registration_id).compact
      elsif notification_type == "legendary" 

        # when user pin message then send notification to its owner
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

        # send notification to message owner + users who replied to that message
        
        final_usersIds = replied_userIds + [message.user_id]
        final_usersIds = final_usersIds.uniq.compact

        final_usersIds.delete(current_user.id)

        users = User.where(id: final_usersIds)
        user_registration_ids = users.map(&:registration_id).compact

        #when user reply on message then send notification to its owner
        notification_title = params[:user][:name]
        notification_body = params[:text]
        params['id'] = message.id # change the parent id
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

  # Get non custom lines under the custom lines by id
  # Custom Line has many non custom lines.
  # Non custom line belongs to Custom line.
  # @message.custom_line - get parent
  # @message.non_custom_lines - get childrens
  def get_non_custom_lines
    message = Message.find(params[:message_id])

    # on landing page if custom line within distance then fetch all its non custom lines + All non custom lines created on Own custom line.
    # if not within distance then fetch only followed lines
    if params[:is_landing_page] == 'true'
      # check this message within 15 yards. if yes it means its all non custom lines are within distance
      # so fetch all non custom line messages
      # Get all non custom lines created on Own custom line.
      undercover_messages = [message]

      messages = Undercover::CheckNear.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        undercover_messages
      ).perform

      if messages.length > 0 || message.user_id = current_user.id
         non_custom_lines = message.non_custom_lines

         non_custom_line_ids = non_custom_lines.map(&:id)
         non_custom_lines = Message.by_ids(non_custom_line_ids)
                                .where.not('(public = false and locked = false)')
      else
        # Only get followed custom lines
        followed_messages = FollowedMessage.where(user_id: current_user)
        followed_message_ids = followed_messages.map(&:message_id)

        non_custom_line_messages = message.non_custom_lines
        custom_line_ids = non_custom_line_messages.map(&:id)

        # Get common elements from both array
        final_message_ids = followed_message_ids & custom_line_ids

        non_custom_lines = Message.by_ids(final_message_ids)
                               .where.not('(public = false and locked = false)')
      end  
    else
       non_custom_lines = message.non_custom_lines 
    end

    render json: {
        messages: non_custom_lines.as_json(
          methods: %i[
            avatar_url image_urls video_urls like_by_user legendary_by_user user
            text_with_links post_url expire_at has_expired is_synced
            locked_by_user is_followed is_connected line_locked_by_user
          ],
          include: [
              :custom_line,:non_custom_lines
          ]          
        )
      }
  end

  # Update the conversation and its messages expiry date
  def conversation_update
    if params[:message][:conversation_line_id]
      #if message_id set then edit the message
      message = Message.find(params[:message][:conversation_line_id])

      message.update(
          message_params.merge(updated_at: Time.at(params[:message][:timestamp].to_i))
      )

      # Update expiry date of messages on conversations lines
      message.conversation_line_messages.update(
          message_params.merge(updated_at: Time.at(params[:message][:timestamp].to_i))
      )

      message.current_user = current_user
      render json: {
          success: true
      }
    else
      render json: {
          success: false
      }
    end
  end

  def show
    message = Message.find(params[:id])
    message.current_user = current_user

    if message.locked == true && params[:grant_access] == 'true'
      grant_access(message.id, current_user.id)

      # auto follow to line
      follow_message(message.id, current_user.id)
    end
    
    if message 
      render json: {
        room_id: message.room.id,
        message: message.as_json(
          methods: %i[
                      avatar_url image_urls video_urls like_by_user legendary_by_user user
                      text_with_links post_url expire_at locked_by_user has_expired is_synced
                      conversation_status
                    ]
        )
      }, status: 200
    else
      render json: {
        message: []
      }, status: :bad_request
    end
  end

  # Fetch Owned communities + Connected communities + Connected Somvos + Owned somvos + All 15 miles Public Community + All 15miles Somvo
  def map_feed
    near_by_communities_and_somvos = []

    near_by_communities_and_somvos = Undercover::CheckNear.new(
        params[:post_code],
        params[:lng],
        params[:lat],
        current_user,
        []
    ).perform

    near_by_communities_and_somvo_ids = near_by_communities_and_somvos.map(&:id)

    #p "near_by_communities_and_somvo_ids #{near_by_communities_and_somvo_ids}"

    followed_messages = FollowedMessage.where(user_id: current_user)
    followed_message_ids = followed_messages.map(&:message_id)

    #p "followed_message_ids #{followed_message_ids}"

    own_communities_and_somvos = Message.where(user_id: current_user)
                                     .by_messageable_type('Network')
                                     .by_not_deleted

    own_communities_and_somvo_ids = own_communities_and_somvos.map(&:id)

    #p "own_communities_and_somvo_ids #{own_communities_and_somvo_ids}"

    # Get joined lines ids
    joined_lines_ids = []
    joined_line_rooms = Room.includes(:rooms_users).where(:rooms_users => {:user_id => current_user.id})
    joined_lines_ids = joined_line_rooms.map(&:message_id)

    if joined_line_rooms.count > 0
      all_joined_lines_ids = "(#{joined_lines_ids.join(',')})"
    else
      # prevented sql error
      all_joined_lines_ids = "(0)"
    end

    #p "all_joined_lines_ids #{all_joined_lines_ids}"

    messageIds = near_by_communities_and_somvo_ids + own_communities_and_somvo_ids + joined_lines_ids
    messageIds = messageIds.uniq

    messages = Message.include_room
                   .by_ids(messageIds)
                   .by_messageable_type('Network')
                   .by_not_deleted
                   .exclude_private_groups
                   .without_blacklist(current_user)
                   .without_deleted(current_user)
                   .with_images
                   .with_videos

    messages.each { |message|
      message.current_user = current_user
    }

    render json: {
        messages: messages.as_json(
            methods: %i[
            avatar_url image_urls video_urls user is_synced text_with_links post_url expire_at has_expired
            conversation_status users_count room_id line_message_type
            like_by_user legendary_by_user is_connected locked_by_user line_locked_by_user
          ]
        )
    }
  end

  private

  def set_room
    @room = Room.find_by(message_id: params[:id])
  end

  def set_message
    @message = Message.find(params[:id])
  end

  # Make line unlocked for current user. Grant access to user for that message
  def grant_access(message_id, user_id)
      lockedMessage = LockedMessage.find_by(message_id: message_id, user_id: user_id)
      if lockedMessage && lockedMessage.unlocked == false
        lockedMessage.update_attributes(unlocked: true)
      end
  end

  def follow_message(message_id, user_id)
    FollowedMessage.find_or_create_by(user_id: user_id, message_id: message_id)
  end

  # Landing page api
  # Look landing page is lines if yours and once around you.
  def get_landing_page_feeds(network, current_ids)
    # get messages from nearby area
    # messages = Undercover::CheckDistance.new(
    #     params[:post_code],
    #     params[:lng],
    #     params[:lat],
    #     current_user,
    #     params[:is_landing_page]
    # ).perform
    #
    # messageIds = messages.map(&:id)

    if params[:is_landing_page] == 'true'
      # on landing page display only public messages within distance 15 miles.
      # Private and semi public should be hide for 15 miles
      # Display followed lines + owned lines
      # Display Joined Lines
=begin
      messages.each { |message|
        if message.public == false
          messageIds.delete(message.id)
        end
      }
=end

      # Get own lines ids
      own_messages = Message.where(user_id: current_user)
                         .by_messageable_type('Network')
                         .by_not_deleted
      own_message_ids = own_messages.map(&:id)

      # Get followed lines ids
      followed_messages = FollowedMessage.where(user_id: current_user)
      followed_message_ids = followed_messages.map(&:message_id)

      # Get joined lines ids
      joined_lines_ids = []
      joined_line_rooms = Room.includes(:rooms_users).where(:rooms_users => {:user_id => current_user.id})
      joined_lines_ids = joined_line_rooms.map(&:message_id)

      total_line_ids = followed_message_ids + own_message_ids + joined_lines_ids
      total_line_ids = total_line_ids.uniq

      total_messages = Message.by_ids(total_line_ids)
                           .by_not_deleted

      #if message is line and it is type of NCL then remove total line ids
      total_messages.each { |message|
        if message.message_type == 'NONCUSTOM_LOCATION' && total_line_ids.include?(message.custom_line_id)
          ##remove message.id from followed_message ids
          followed_message_ids.delete(message.id)
          own_message_ids.delete(message.id)
          joined_lines_ids.delete(message.id)
        end
      }

      # messageIds = messageIds + followed_message_ids + own_message_ids + joined_lines_ids
      messageIds = followed_message_ids + own_message_ids + joined_lines_ids
      messageIds = messageIds.uniq
    end

    # Fetch conversation + Lines(own) + Lines(followed) + Lines(within distance even if not followed)
    # Do not show messages on Line at landing page
    # Removed messages of conversation from LP
    undercover_messages = Message
                              .include_room
                              .by_ids(messageIds)
                              .by_not_deleted
                              .without_blacklist(current_user)
                              .without_deleted(current_user)
                              .by_messageable_type('Network')
                              .where("
                                ((expire_date IS NULL OR expire_date > :current_date) and (message_type != 'LOCAL_MESSAGE' OR message_type is null))
                                  OR
                                (message_type = 'LOCAL_MESSAGE' AND (updated_at > :local_message_expiry_date OR expire_date > :current_date))",
                                {
                                  current_date: DateTime.now,
                                  local_message_expiry_date: DateTime.now - 3.days
                                })
                              .with_images
                              .with_videos
                              .with_non_custom_lines
                              .sort_by_last_messages(params[:limit], params[:offset])

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
  end

  def get_public_area_page_feeds(network, current_ids)
    if params[:is_distance_check] == 'true'
      # Local Mode
      # Show Legendary Public/Private Messages within 15 miles. When something is legendary, it basically becomes public
      # Show Public Local Messages within 15 miles (Do not show messages of Local Messages)
      # Show messages of Public Communities within 15 miles (Do not show community itself)

      legendary_near_by_messages = LegendaryLike.all

      legendary_message_ids = legendary_near_by_messages.map(&:message_id).uniq.join(',')

      if legendary_near_by_messages.count > 0
        legendary_near_by_message_ids = "(#{legendary_message_ids})"
      else
        # prevented sql error
        legendary_near_by_message_ids = "(0)"
      end

      messages = Message
                     .where("((messageable_type = 'Network' and message_type = 'LOCAL_MESSAGE')
                                OR (messageable_type = 'Room' and undercover = true and (message_type is null OR (message_type != 'CONV_REQUEST' AND message_type != 'CONV_ACCEPTED' AND message_type != 'CONV_REJECTED'))
                            ))")
                     .where("
                          messages.public = true
                          or (messages.id in #{legendary_near_by_message_ids})
                      ")
                     .by_not_deleted
                     .without_blacklist(current_user)
                     .without_deleted(current_user)
                     .sort_by_newest

      near_by_messages = Undercover::CheckNear.new(
          params[:post_code],
          params[:lng],
          params[:lat],
          current_user,
          messages
      ).perform

      near_by_message_ids = near_by_messages.map(&:id).uniq

      messages = Message
                     .by_ids(near_by_message_ids)
                     .with_images
                     .with_videos
                     .with_non_custom_lines
                     .include_room
                     .with_messageble
                     .sort_by_last_messages(params[:limit], params[:offset])

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
      # World Mode
      # Show Legendary Public/Private Messages. When something is legendary, it basically becomes public
      # Do Not Show Local Messages. There is no point as they are only for local use.
      # Show messages of Public Communities (Do not show community itself)

      legendary_near_by_messages = LegendaryLike.all

      legendary_message_ids = legendary_near_by_messages.map(&:message_id).uniq.join(',')

      if legendary_near_by_messages.count > 0
        legendary_near_by_message_ids = "(#{legendary_message_ids})"
      else
        # prevented sql error
        legendary_near_by_message_ids = "(0)"
      end

      messages = Message
                     .where("(
                              (messageable_type = 'Room' and undercover = true and (message_type is null OR (message_type != 'CONV_REQUEST' AND message_type != 'CONV_ACCEPTED' AND message_type != 'CONV_REJECTED'))
                            ))")
                     .where("
                          messages.public = true
                          or (messages.id in #{legendary_near_by_message_ids})
                      ")
                     .by_not_deleted
                     .without_blacklist(current_user)
                     .without_deleted(current_user)
                     .sort_by_newest

      world_message_ids = messages.map(&:id).uniq

      messages = Message
                     .by_ids(world_message_ids)
                     .with_images
                     .with_videos
                     .with_non_custom_lines
                     .include_room
                     .with_messageble
                     .sort_by_last_messages(params[:limit], params[:offset])

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
    end
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
      :message_type,
      :avatar,
      :custom_line_id,
      :conversation_line_id,
      :user_public_profile
    )
  end
end
