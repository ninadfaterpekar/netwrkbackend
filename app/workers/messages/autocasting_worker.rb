module Messages
  class AutocastingWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform
      User.all.each do |user|
        Autocasting::FetchFromSocials.new(user: user).perform
      end
    end
  end
end