class Facebook::FeedFetch
  include Service

  require 'koala'

  def initialize(user, amount_of_posts)
    @user = user
    @amount_of_posts = amount_of_posts
  end

  def perform
    find_providers
    get_feed
    find_messages
  rescue Exception => e
    errors.add :feet_fetch, e.to_s
  end

  private

  attr_reader :user, :access_token, :feed, :amount_of_posts

  def find_providers
    @access_token = user.providers.by_name('fb').last.token
  end

  def get_feed
    graph = Koala::Facebook::API.new(@access_token)
    @feed = graph.get_connection(
      'me', 'posts', fields: %w[
        id message full_picture created_time privacy link place permalink_url
        attachments source
      ]
    )
  end

  def find_messages
    feed.slice!(amount_of_posts, feed.count - amount_of_posts)
    feed.each { |message| save_message(message) }
  end

  # TODO: refactor dis method
  def save_message(message)
    old_message = Message.find_by(
      user_id: user.id,
      social: 'facebook',
      social_id: message['id'],
      created_at: message['created_time'],
      undercover: false,
      url: message['link'],
      messageable: nil,
      post_code: nil,
      post_permalink: message['permalink_url']
    )
    return if old_message.present?
    new_message = Message.new(
      text: message['message'],
      user_id: user.id,
      social: 'facebook',
      social_id: message['id'],
      created_at: message['created_time'],
      undercover: false,
      url: message['link'],
      post_permalink: message['permalink_url']
    )
    if message['source'].present?
      new_message.videos.new(url: message['source'], thumbnail_url: message['full_picture'])
    elsif message['full_picture'].present?
      new_message.images.new(url: message['full_picture'])
    end
    if message['attachments'].present?
      if message['attachments']['data'].first['subattachments'].present?
        message['attachments']['data'].first['subattachments']['data'].each do |a|
          if a['type'] == 'video'
            new_message.videos.new(url: a['url'], thumbnail_url: a['media']['image']['src'])
          end
        end
      end
    end
    new_message.save
  end
end
