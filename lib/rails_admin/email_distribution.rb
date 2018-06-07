module RailsAdmin
  module Config
    module Actions
      class EmailDistribution < RailsAdmin::Config::Actions::Base
        register_instance_option :collection do
          true
        end
        register_instance_option :http_methods do
          %i[get post]
        end
        register_instance_option :link_icon do
          'fa fa-envelope'
        end
        register_instance_option :controller do
          proc do
            if request.get?
              render @action.template_name
            else
              if TemplatesMailer.get_subject(params[:template_name])
                Emails::DistributionWorker.perform_async(params[:template_name])
                redirect_to rails_admin.email_distribution_path(
                  model_name: 'user'
                ), notice: 'emails successfully sent.'
              else
                @errors = 'Template \'' + params[:template_name] + '\' Not Found!'
                render @action.template_name
              end
            end
          end
        end
      end
    end
  end
end
