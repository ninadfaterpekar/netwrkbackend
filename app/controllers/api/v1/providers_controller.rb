class Api::V1::ProvidersController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def create
    current_user.providers << Provider.new(provider_params)
    render json: { status: 'ok' }, status: 200
  end

  private

  def provider_params
    params.require(:provider).permit(
      :name,
      :token,
      :secret
    )
  end
end
