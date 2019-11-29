class Message < ApplicationRecord
  include ActionView::Helpers::DateHelper
  include SetMessageableType

  belongs_to :messageable, polymorphic: true, required: false
  belongs_to :owner, foreign_key: :user_id, class_name: 'User'
  has_many :images, dependent: :destroy
  has_many :videos, dependent: :destroy

  has_many :reports, as: :reportable, dependent: :destroy

  has_many :user_likes, dependent: :destroy
  has_many :liked_users, through: :user_likes, class_name: 'User'

  has_many :locked_messages, dependent: :destroy
  has_many :locked_users, through: :locked_messages, class_name: 'User'

  has_many :user_followed, dependent: :destroy
  has_many :followed_users, through: :user_followed, class_name: 'User'

  has_many :followed_messages, dependent: :destroy

  has_many :legendary_likes, dependent: :destroy
  has_many :legendary_users, through: :legendary_likes, class_name: 'User'

  has_many :deleted_messages, dependent: :destroy
  has_many :users, through: :deleted_messages

  has_one :room, dependent: :destroy
  has_many :replies, dependent: :destroy

  has_many :non_custom_lines, class_name: "Message", foreign_key: "custom_line_id"
  belongs_to :custom_line, class_name: "Message", counter_cache: :lines_count

  belongs_to :conversation_line, class_name: "Message", foreign_key: "conversation_line_id"
  has_many :conversation_line_messages, class_name: "Message", foreign_key: "conversation_line_id"

  has_attached_file :avatar, styles: {
    medium: '256x256#', thumb: '100x100>'
  }, default_url: '/images/missing.png'
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\z/

  validates :text, obscenity: { sanitize: true }

  scope :by_ids, ->(ids) { where(id: ids) }
  scope :by_messageable_ids, ->(ids) { where(id: ids) }
  scope :without_blacklist, ->(user) {
    where.not(user_id: user.blacklist.pluck(:target_id))
  }
  scope :by_unlocked, -> { where(locked: false) }
  scope :with_unlocked, ->(user_id) do
    messages = joins(:locked_messages).merge(
      LockedMessage.where(user_id: user_id, unlocked: false)
    )
    where.not(id: messages)
  end
  scope :without_deleted, ->(user) {
    ids_to_exclude = user.messages_deleted.pluck('deleted_messages.message_id')
    without_ids(ids_to_exclude)
  }
  scope :without_ids, ->(ids) { where.not(id: ids) }
  scope :with_images, -> { includes(:images) }
  scope :with_videos, -> { includes(:videos) }
  scope :with_users, -> { includes(:users) }
  scope :with_non_custom_lines, -> { includes(:non_custom_lines) }
  scope :undercover_is, ->(bool) { where(undercover: bool) }
  scope :public_is, ->(bool) { where(public: bool) }
  scope :locked_is, ->(bool) { where(locked: bool) }
  scope :by_not_deleted, -> { where(deleted: false) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_social, ->(social) { where(social: social) }
  scope :legendary_messages, ->(ids) {
    joins(:legendary_likes).merge(LegendaryLike.where(message_id: ids))
  }
  scope :joins_legendary_messages, -> {
    joins(:legendary_likes).merge(LegendaryLike.where(message_id: ids))
  }
  scope :joins_room, -> {
    left_joins(:room).merge(Room.where(message_id: ids))
  }
  scope :include_room, -> { includes(:room) }

  scope :sort_by_latest_id, -> { order(id: :desc) }
  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :sort_by_points_highest, -> { order(points: :desc) }
  scope :by_post_code, ->(post_code) { where(post_code: post_code) }
  scope :by_messageable_type, ->(type) { where(messageable_type: type)}
  scope :by_messageable, ->(id, type = nil) do
    where(messageable_id: id, messageable_type: type)
  end
  scope :by_room, ->(room_id) do
    where(messageable_id: room_id, messageable_type: :Room)
  end
  scope :by_network, ->(network_id) do
    where(messageable_id: network_id, messageable_type: :Network)
  end
  scope :with_room, ->(message_id) do
    joins(:room).merge(Room.where(message_id: message_id))
  end

  scope :sort_by_last_messages, ->(limit, offset) {
    sort_by_newest.limit(limit).offset(offset)
  }

  scope :sort_by_last_messages_id, ->(limit, offset) {
    sort_by_latest_id.limit(limit).offset(offset)
  }

  scope :sort_by_points, ->(limit, offset) {
    sort_by_points_highest.limit(limit).offset(offset)
  }

  URI_REGEX = %r{((?:(?:[^ :/?#]+):)(?://(?:[^ /?#]*))(?:[^ ?#]*)(?:\?(?:[^ #]*))?(?:#(?:[^ ]*))?)}

  attr_accessor :current_user, :is_conversation

  def legendary?
    !legendary_count.zero?
  end

  def avatar_url
    'https:' + avatar.url(:medium)
  end

  def image_urls
    urls = []
    images.each do |image|
      puts ActionController::Base.helpers.asset_path(image.image.url(:medium))
      urls << (image.url.present? ? image.url : 'https:' + image.image.url(:medium))
    end
    urls
  end

  def video_urls
    urls = []
    videos.each do |video|
      hash = {}
      hash[:poster] = video.thumbnail_url
      hash[:url] = (video.url.present? ? video.url : video.video.url)
      urls << hash
    end
    urls
  end

  def post_url
    post_permalink.present? ? URI.decode(post_permalink) : ''
  end

  def deleted_by_user?(user = current_user)
    users.include?(user)
  end

  def like_by_user(user = current_user)
    liked_users.include?(user)
  end

  def legendary_by_user(user = current_user)
    legendary_users.include?(user)
  end

  def timestamp
    created_at.to_i
  end

  def locked_by_user(user = current_user)

    if locked
      m = LockedMessage.find_by(message_id: id, user_id: user.id)
      m.present? ? !m.unlocked : true
    else
      false
    end
  end

  def line_locked_by_user(user = current_user)
    if messageable_type == 'Network'
      if room
        m = LockedMessage.where(message_id: room.message_id)
            .where(unlocked: false)
            .where(user_id: user.id)
         return m.present? ? true : false
      else
         return false
      end  
    end

    if messageable_type == 'Room' 
      roomMessage = Room.find_by(id: messageable_id)
        if roomMessage
          m = LockedMessage.where(message_id: roomMessage.message_id)
              .where(unlocked: false)
              .where(user_id: user.id)
          m.present? ? true : false
        else
          false
        end
    end
  end

  def is_followed(user = current_user)
    m = FollowedMessage.find_by(user_id: user, message_id: id)
    m.present? ? true : false
  end

  def is_connected(user = current_user)
    if messageable_type == 'Network'
      m = RoomsUser.find_by(user_id: user, room_id: room_id)
      m.present? ? true : false
    elsif messageable_type == 'Room'
      m = RoomsUser.find_by(user_id: user, room_id: messageable_id)
      m.present? ? true : false
    else
      true
    end
  end

  def line_message_type
    if undercover == true
      if messageable_type == 'Network'
        if locked
          return 'PRIVATE_LINE'
        else
          return 'PUBLIC_LINE'
        end
      elsif messageable_type == 'Room'
        if room.message.public == false && room.message.locked == false
          # semi private
          return 'SEMI_PRIVATE_LINE'
        elsif room.message.public == false && room.message.locked == true && room.message.undercover == true
          # private
          return 'PRIVATE_LINE'
        elsif room.message.public == true && room.message.undercover == true
          return 'PUBLIC_LINE'
        end
      else
        return 'REPLY'
      end
    else
      # conversation local message
      return 'LOCAL_MESSAGE'
    end
  end

  def users_count
    if room.present?
      room.users_count
    else
      0
    end
  end

  def room_id
    if room.present?
      room.id
    else
      NIL
    end
  end

  def conversation_status
    conversation_request_status = nil
    if message_type == 'CONV_REQUEST'
      if conversation_line.present? and conversation_line.room.present?
        # if rooms_users table have entry with current_user and conversation__line_id then accepted
        conversation_line_room_user =  RoomsUser.find_by(room_id: conversation_line.room.id, user_id: current_user.id)

        if conversation_line_room_user.present?
          conversation_request_status = 'ACCEPTED'
        else
          is_conversation_request_rejected = Message.find_by(user_id: current_user.id,
                                                             messageable_id: conversation_line.room.id,
                                                             messageable_type: 'Room',
                                                             message_type: 'CONV_REJECTED')
          if is_conversation_request_rejected.present?
            conversation_request_status = 'REJECTED'
          else
            conversation_request_status = 'REQUESTED'
          end
        end
      end
    elsif message_type == 'LOCAL_MESSAGE'
      # if current user is joined to conversation_line (having rooms_users table entry) then request is accepted.
      # If current user is rejected to conversation request (having rejected entry for that conversation in message table) then request is rejected
      # If neither have entry in rooms_users nor in messages (rejected) then request status is requested

      if room.present?
        conversation_line_room_user =  RoomsUser.find_by(room_id: room.id, user_id: current_user.id)

        if conversation_line_room_user.present?
          conversation_request_status = 'ACCEPTED'
        else
          is_conversation_request_rejected = Message.find_by(user_id: current_user.id,
                                                             messageable_id: room.id,
                                                             messageable_type: 'Room',
                                                             message_type: 'CONV_REJECTED')
          if is_conversation_request_rejected.present?
            conversation_request_status = 'REJECTED'
          else
            conversation_request_status = 'REQUESTED'
          end
        end
      end
    end

    return conversation_request_status
  end

  def make_locked(args)
    salt = SecureRandom.base64(8)
    update_columns(
      locked: true,
      hint: args[:hint],
      password_salt: salt,
      password_hash: Digest::SHA2.hexdigest(salt + args[:password])
    )
  end

  def make_unlocked(args)
    salt = SecureRandom.base64(8)
    update_columns(
      locked: false,
      hint: args[:hint],
      password_salt: salt,
      password_hash: ''
    )
  end

  def text_with_links
    return if text.nil?
    return text if text.include?('</a>')
    text.split(URI_REGEX).collect do |s|
      valid_url?(s) ? "<a href='#{s}'>#{s}</a>" : s
    end.join
  end

  def valid_url?(uri)
    uri = URI.parse(uri)
    !uri.host.nil?
  rescue
    false
  end

  def correct_password?(password)
    password_hash == Digest::SHA2.hexdigest(password_salt + password)
  end

  def user
    u = User.find_by(id: user_id)
    u.as_json(methods: %i[id avatar_url hero_avatar_url], only: %i[name role_name])
  end

  def expire_at
    expire_date.present? ? distance_of_time_in_words(Time.now, expire_date) : ''
  end

  def has_expired
    expire_date.present? && DateTime.now > expire_date
  end

  def post_url=(post_url)
    self.post_permalink = post_url
  end

  def is_synced
    true
  end
end
