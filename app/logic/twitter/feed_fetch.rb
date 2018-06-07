class Twitter::FeedFetch
  include Service

  def initialize(user, amount_of_posts)
    @user = user
    @amount_of_posts = amount_of_posts
  end

  def perform
    find_providers
    find_messages
  rescue Twitter::Error::TooManyRequests => e
    puts "Oh shit here come dat error #{e.inspect}"
  rescue Exception => e
    p '=' * 300
    p e
  end

  private

  attr_reader :user, :provider, :client, :amount_of_posts

  def find_providers
    @provider = user.providers.by_name('twitter').last
  end

  def find_messages
    if provider.present?
      feed = get_feed
      feed.each do |post|
        link = post.url.to_s
        save_message(post, link)
      end
    end
  end

  def get_feed
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = provider.token # "760065835520159745-isrRmAW1O0s92J2GTmkKlCojASehsWk"
      config.access_token_secret = provider.secret # "TtxSuN1A7UnRJBWARFR6c9nEjcKoeiCYXYMrfTCKIPaEy"
    end
    feed = client.user_timeline(count: amount_of_posts)
  end

  def save_message(post, link)
    return unless client.user.id == post.user.id
    old_message = Message.find_by(
      user_id: user.id,
      social: 'twitter',
      social_id: post.id.to_s,
      messageable: nil,
      created_at: post.created_at,
      post_code: nil,
      undercover: false
    )
    return if old_message.present?
    return unless post.text.present?
    new_message = Message.create(text: post.text,
                                 user_id: user.id,
                                 social: 'twitter',
                                 social_id: post.id.to_s,
                                 created_at: post.created_at,
                                 undercover: false,
                                 post_permalink: link)
  end
end
