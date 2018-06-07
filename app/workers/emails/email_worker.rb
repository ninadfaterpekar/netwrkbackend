module Emails
  class InvitationToAreaWorker
    include Sidekiq::Worker

    def perform(contact_list)
      contact_list['invitation'].each do |contact|
        if contact['email'].present?
          TemplatesMailer.invitation_to_area(contact['email']).deliver_now
        end
      end
    end
  end
end
