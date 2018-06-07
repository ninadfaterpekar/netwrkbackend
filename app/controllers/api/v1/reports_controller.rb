class Api::V1::ReportsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token, :check_token
  before_action :delete_message, only: [:message]

  def user
    user = User.find(params[:id])
    if user.present?
      user.reports.create(user_id: current_user.id, reasons: params[:reasons])
      render json: { message: 'ok' }, status: 200
    else
      render json: { message: 'User not found' }, status: 404
    end
  end

  def message
    if @message.present?
      @message.reports.create(
        user_id: current_user.id, reasons: params[:reasons]
      )
      render json: { message: @notice }, status: 200
    else
      render json: { message: 'Message not found' }, status: 404
    end
  end

  private

  def delete_message
    @message = Message.find(params[:id])
    return @notice = 'del' if @message.deleted
    reports_count = Report.by_type('Message')
                          .by_ids(@message.id)
                          .map(&:user_id).uniq.count
    return @notice = 'ok' unless reports_count >= Report::AMOUNT_TO_REMOVE - 1
    @message.update_attributes(deleted: true)
    @notice = 'del'
  end
end
