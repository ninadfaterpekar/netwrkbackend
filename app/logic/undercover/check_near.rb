class Undercover::CheckNear
  include Service

  def initialize(post_code, current_lng, current_lat, user)
    @post_code = post_code
    @current_lng = current_lng
    @current_lat = current_lat
    @user = user
  end

  def perform
    messages_in_radius
  end

  private
  attr_reader :post_code, :user, :current_lng, :current_lat

  def messages_in_radius

    messages_in_radius = []
    
    # on landing page display own conversation + Lines (any user)
    messages = Message.undercover_is(true).with_users

    messages.each do |message|
      next unless (message.lat.to_s[0..3] == current_lat.to_s[0..3]) ||
                  (message.lng.to_s[0..3] == current_lng.to_s[0..3])
      distance = Geocoder::Calculations.distance_between(
        [current_lng, current_lat], [message.lng, message.lat]
      )
      message.current_user = user
      if in_radius?(miles_to_yards(distance), 26400) && !message.deleted_by_user?
        messages_in_radius << message
      end
    end
    messages_in_radius
  end

  def miles_to_yards(miles)
    miles * 1760
  end

  def in_radius?(yards, limitInYards)
    #26400 yards = 15 miles
    yards <= limitInYards
  end

end
