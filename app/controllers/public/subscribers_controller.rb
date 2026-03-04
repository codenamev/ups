class Public::SubscribersController < ActionController::Base
  protect_from_forgery with: :exception
  layout "public"
  before_action :set_status_page

  def create
    @subscriber = @status_page.subscribers.build(subscriber_params)
    @subscriber.account = @status_page.account

    respond_to do |format|
      if @subscriber.save
        # Send confirmation email here (if needed)
        format.html { redirect_to public_status_page_path(@status_page.slug), notice: "Successfully subscribed! You'll receive notifications for any incidents." }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("subscription-section",
            partial: "public/status_pages/subscription_success",
            locals: { status_page: @status_page })
        }
      else
        format.html { redirect_to public_status_page_path(@status_page.slug), alert: @subscriber.errors.full_messages.join(", ") }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("subscription-section",
            partial: "public/status_pages/subscription_form",
            locals: { status_page: @status_page, subscriber: @subscriber })
        }
      end
    end
  end

  def destroy
    @subscriber = @status_page.subscribers.find_by!(confirmation_token: params[:token])
    @subscriber.destroy!

    redirect_to public_status_page_path(@status_page.slug),
                notice: "You have been successfully unsubscribed from notifications."
  end

  private

  def set_status_page
    @status_page = StatusPage.find_by!(slug: params[:slug])
  end

  def subscriber_params
    params.permit(:email)
  end
end
