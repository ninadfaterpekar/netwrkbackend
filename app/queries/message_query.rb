class MessageQuery
  def initialize(current_user)
    @current_user = current_user
  end

  def from_socials(limit, offset, socials = %w[facebook twitter instagram])
    Message.by_user(current_user.id)
           .by_social(socials)
           .by_post_code(nil).by_messageable(nil)
           .sort_by_last_messages(limit, offset)
  end

  def profile(user, post_code, method, limit, offset)
    if method == true
      # Fetch Own Somvos
      Message.by_user(user.id)
          .by_somvo_only
          .by_not_deleted
          .without_blacklist(user)
          .sort_by_last_messages(limit, offset)
    else
      # Fetch Own Communities
      Message.by_user(user.id)
          .by_communities_only
          .by_not_deleted
          .without_blacklist(user)
          .sort_by_last_messages(limit, offset)
    end
  end

  def latest_message(user, post_code, method, limit, offset)
    Message.by_user(user.id)
           .by_post_code(post_code)
           .by_messageable_type(:Network)
           .public_is(method)
           .sort_by_last_messages_id(limit, offset)
           .by_not_deleted
           .without_blacklist(user)
           .with_unlocked(current_user.id)
  end

  def communities(limit, offset)
    followed_messages = FollowedMessage.where(user_id: current_user.id)
    followed_message_ids = followed_messages.map(&:message_id)

    own_messages = Message.by_user(current_user.id)
                          .by_not_deleted
                          .by_messageable_type(:Network)
    own_message_ids = own_messages.map(&:id)

    joined_lines_ids = []
    joined_line_rooms = Room.includes(:rooms_users).where(:rooms_users => {:user_id => current_user.id})
    joined_lines_ids = joined_line_rooms.map(&:message_id)

    total_line_ids = (followed_message_ids + own_message_ids + joined_lines_ids).uniq

    messages = Message.by_ids(total_line_ids)
                      .undercover_is(true)
                      .by_not_deleted
                      .by_messageable_type(:Network)
                      .sort_by_last_messages(limit, offset)

    return messages
  end

  private

  attr_reader :current_user
end
