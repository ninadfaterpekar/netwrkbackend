class TemplatesMailer < MandrillMailer::TemplateMailer
  default from: 'team@netwrkapp.app'

  def send_template(template_name, email)
    subject = TemplatesMailer.get_subject(template_name)
    mandrill_mail(
      template: template_name,
      subject: subject,
      to: email,
      important: true,
      inline_css: true
    )
  end

  def welcome(email)
    name = ApplicationSetting.instance.email_welcome
    subject = TemplatesMailer.get_subject(name) ||
      'Welcome: Arch\'s first day in netwrk'
    mandrill_mail(
      template: name,
      subject: subject,
      to: email,
      important: true,
      inline_css: true
    )
  end

  def connect_mail(email)
    name = ApplicationSetting.instance.email_connect_to_network
    subject = TemplatesMailer.get_subject(name) ||
      'Society connect: couple important things'
    mandrill_mail(
      template: name,
      subject: subject,
      to: email,
      important: true,
      inline_css: true
    )
  end

  def legendary_mail(email)
    name = ApplicationSetting.instance.email_legendary_mail
    subject = TemplatesMailer.get_subject(name) ||
      'Your cast was added to society\'s story'
    mandrill_mail(
      template: name,
      subject: subject,
      to: email,
      important: true,
      inline_css: true
    )
  end

  def invitation_to_area(email) # invite people to grow area
    name = ApplicationSetting.instance.email_invitation_to_area
    subject = TemplatesMailer.get_subject(name) || 'Invitation to area'
    mandrill_mail(
      template: name,
      subject: subject,
      to: email,
      important: true,
      inline_css: true
    )
  end

  def self.get_subject(template_name)
    mandrill = Mandrill::API.new ENV['MANDRILL_API_KEY_PROD']
    result = mandrill.templates.info(template_name)
    result['subject']
  rescue Mandrill::UnknownTemplateError => e
    p e
    return false
  end
end
