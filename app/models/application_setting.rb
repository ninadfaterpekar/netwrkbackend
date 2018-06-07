class ApplicationSetting < ApplicationRecord
  validates_inclusion_of :singleton_guard, in: [0]

  def self.instance
    row = find_by(singleton_guard: 0)
    return row unless row.nil?
    row = ApplicationSetting.new
    row.singleton_guard = 0
    row.home_page = ''
    row.email_welcome = ''
    row.save!
    row
  end
end
