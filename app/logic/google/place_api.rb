class Google::PlaceApi
  include Service

  attr_accessor :place_id, :v_place

  def initialize(place_id)
    @place_id = place_id
  end

  def perform
    return v_place if existing_place
    create_place
  end

  private

  require 'open-uri'

  def existing_place
    @v_place = City.find_by(google_place_id: place_id)
  end

  def create_place
    key = ENV['GOOGLE_PLACE_API_KEY']
    place = City.new(google_place_id: place_id)
    data = JSON.load(open("https://maps.googleapis.com/maps/api/place/details/json?place_id=#{place_id}&key=#{key}"))
    result = data['result']
    result['address_components'].each do |address|
      if (address['types'].first == 'locality') ||
         (address['types'].first == 'administrative_area_level_3' && place.name.nil?)
        place.attributes = { name: address['long_name'] }
      end
    end
    place if place.save
  end
end
