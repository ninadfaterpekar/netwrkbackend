class Instagram::FeedFetch
  include Service

  def initialize(user, amount_of_posts)
    @user = user
    @amount_of_posts = amount_of_posts
  end

  def perform
    return unless fetch_feed
    save_instagram_feed
    #save_messages
  end

  private

  attr_reader :user, :amount_of_posts, :feed

  def fetch_feed
    provider = Provider.find_by(user_id: user.id, name: 'instagram')
    return false if provider.nil?

    callback_url = 'https://api.somvo.app/loader'
    begin
      if provider.secret.nil?
        endpoint = 'https://api.instagram.com'

        # call zogata api to insert activity
        conn = Faraday.new(url: endpoint) do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to $stdout
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end

        requestData = {
          "client_id" => ENV['INSTAGRAM_CLIENT_ID'],
          "client_secret" => ENV['INSTAGRAM_CLIENT_SECRET'],
          "grant_type" => 'authorization_code',
          "redirect_uri" => callback_url,
          "code" => provider.token
        }

        codeApiResponse = conn.post do |req|
          req.url endpoint + '/oauth/access_token'
          req.body = requestData
        end

        # short lived access token
        parsedCodeApiResponse = JSON.parse(codeApiResponse.body)
        access_token = parsedCodeApiResponse['access_token']

        # get long lived access token from short lived access token
        instagram_endpoint = 'https://graph.instagram.com'

        conn = Faraday.new(url: instagram_endpoint) do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to $stdout
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end

        apiResponse = conn.get do |req|
          req.url instagram_endpoint + '/access_token?grant_type=ig_exchange_token&client_secret='+ENV['INSTAGRAM_CLIENT_SECRET']+'&access_token='+access_token
        end

        parsedApiResponse = JSON.parse(apiResponse.body)
        long_lived_access_token = parsedApiResponse['access_token']

        provider.update_attributes(secret: long_lived_access_token, provider_id: parsedCodeApiResponse['user_id'])
      else
        endpoint = "https://graph.instagram.com"
        # call zogata api to insert activity
        conn = Faraday.new(url: endpoint) do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to $stdout
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end
        # long_lived_access_token = 'IGQVJYbVBrWHliSklULUd0YUdfclZAGRm9zV2dNeDRPV2hYUTdUWm5renVmX2lUMlpRdlpQVnlTM0szbWhxWkpqcGwyN0VzVmlpQUZAaa3l0U3NpN2V5QmpkNUMydlgzZAG1MM29fdC1B'
        long_lived_access_token = provider.secret
        apiResponse = conn.get do |req|
          req.url '/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url,timestamp,username&access_token='+ long_lived_access_token;
        end

        @feed = JSON.parse(apiResponse.body)
      end

    rescue Instagram::BadRequest => e
      p '--------------------' * 5
      p e.message

=begin
      if e.message =~ /access_token provided is invalid/
        provider.destroy
        Message.by_user(user.id)
               .by_social('instagram')
               .by_post_code(nil).by_network(nil)
               .destroy_all
      end
=end
      false
    end
  end

  def save_instagram_feed
    if feed.present?
      feed['data'].each do |post|
        caption = post['caption'].present? ? post['caption'] : ''
        created_time = post['timestamp']

        old_message = Message.find_by(
            user_id: user.id,
            social: 'instagram',
            social_id: post['id'].to_s,
            created_at: DateTime.strptime(created_time, '%s'),
            messageable: nil,
            post_code: nil,
            undercover: false
        )

        next if old_message.present?
        new_message = Message.create(text: caption,
                                     user_id: user.id,
                                     social: 'instagram',
                                     social_id: post['id'].to_s,
                                     created_at: DateTime.strptime(created_time),
                                     undercover: false,
                                     post_permalink: post['permalink'])

        if post['media_url'].present?
          if post['media_type'] == 'CAROUSEL_ALBUM'
            new_message.images << Image.create(url: post['media_url'])
          elsif post.type == 'video'
            new_message.videos << Video.create(url: post.videos.standard_resolution.url, thumbnail_url: post.images.standard_resolution.url)
          end
        end
      end
    end
  end

  def save_messages
    if feed.present?
      feed.each do |post|
        begin
          caption = post.caption.text
          created_time = post.caption.created_time
        rescue
          caption = post.caption
          created_time = post.created_time
        end
        old_message = Message.find_by(
          user_id: user.id,
          social: 'instagram',
          social_id: post.id.to_s,
          created_at: DateTime.strptime(created_time, '%s'),
          messageable: nil,
          post_code: nil,
          undercover: false
        )
        next if old_message.present?
        new_message = Message.create(text: caption,
                                     user_id: user.id,
                                     social: 'instagram',
                                     social_id: post.id.to_s,
                                     created_at: DateTime.strptime(created_time, '%s'),
                                     undercover: false,
                                     post_permalink: post.link)
        if post.carousel_media.present?
          post.carousel_media.each do |media|
            if media.type == 'image'
              new_message.images << Image.create(url: media.images.standard_resolution.url)
            elsif media.type == 'video'
              new_message.videos << Video.create(url: media.videos.standard_resolution.url)
            end
          end
        else
          if post.type == 'image'
            new_message.images << Image.create(url: post.images.standard_resolution.url)
          elsif post.type == 'video'
            new_message.videos << Video.create(url: post.videos.standard_resolution.url, thumbnail_url: post.images.standard_resolution.url)
          end
        end
      end
    end
  end
end
