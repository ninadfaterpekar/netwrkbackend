class Api::V1::InvitationsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token, :check_token

  def create
    contact_list = invite_params.to_h
    Email::InvitationToAreaWorker.perform_async(contact_list)
    render json: { status: 'success' }, status: 200
  rescue Exception => e
    p e
    p '-' * 300
    render json: { message: e, status: 'Something went wrong' }, status: 422
  end

  def sms
    Twilio::Connect.new('+380963855593', '1234').perform
    render json: { success: 'ok' }, status: 200
  end

  private

  def invite_params
    params.permit(invitation: %i[name email phone])
  end
end
