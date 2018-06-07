module Emails
  class DistributionWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(template_name)
      User.all.each do |user|
        TemplatesMailer.send_template(template_name, user.email).deliver_now
      end
    end
  end
end