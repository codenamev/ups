class UnsubscribeController < ApplicationController
  skip_before_action :authenticate_user!
  layout false

  def show
    @subscriber = find_subscriber
    if @subscriber.nil?
      render :invalid_token
    end
  end

  def confirm
    @subscriber = find_subscriber
    if @subscriber.nil?
      render :invalid_token
      return
    end

    @status_page = @subscriber.status_page
    if @subscriber.update(unsubscribed_at: Time.current)
      render :confirmed
    else
      redirect_to unsubscribe_path(params[:token]), alert: "There was an error processing your unsubscribe request."
    end
  end

  private

  def find_subscriber
    Subscriber.find_by(unsubscribe_token: params[:token])
  end
end
