class UnsubscribeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :find_subscriber

  def show
    # Show confirmation page
    @subscriber = find_subscriber
    if @subscriber.nil?
      redirect_to root_path, alert: "Invalid unsubscribe link."
      return
    end
  end

  def confirm
    @subscriber = find_subscriber
    if @subscriber.nil?
      redirect_to root_path, alert: "Invalid unsubscribe link."
      return
    end

    if @subscriber.update(unsubscribed_at: Time.current)
      redirect_to root_path, notice: "You have been successfully unsubscribed from #{@subscriber.status_page.name} notifications."
    else
      redirect_to unsubscribe_path(params[:token]), alert: "There was an error processing your unsubscribe request."
    end
  end

  private

  def find_subscriber
    @subscriber ||= Subscriber.find_by(unsubscribe_token: params[:token])
  end
end