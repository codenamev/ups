# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < Api::BaseController
      before_action :set_status_page
      before_action :set_webhook, only: [:show, :update, :destroy]

      # GET /api/v1/status_pages/:status_page_id/webhooks
      def index
        webhooks = @status_page.webhooks.order(:created_at)
        render json: { webhooks: webhooks.map { |w| serialize(w) } }
      end

      # GET /api/v1/status_pages/:status_page_id/webhooks/:id
      def show
        render json: { webhook: serialize(@webhook) }
      end

      # POST /api/v1/status_pages/:status_page_id/webhooks
      def create
        webhook = @status_page.webhooks.build(webhook_params)
        webhook.account = current_account

        if webhook.save
          render json: { webhook: serialize(webhook, include_secret: true) }, status: :created
        else
          render json: { error: { code: "validation_failed", message: webhook.errors.full_messages.join(", ") } }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/status_pages/:status_page_id/webhooks/:id
      def update
        if @webhook.update(webhook_params)
          render json: { webhook: serialize(@webhook) }
        else
          render json: { error: { code: "validation_failed", message: @webhook.errors.full_messages.join(", ") } }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/status_pages/:status_page_id/webhooks/:id
      def destroy
        @webhook.destroy!
        head :no_content
      end

      private

      def set_status_page
        @status_page = current_account.status_pages.find(params[:status_page_id])
      end

      def set_webhook
        @webhook = @status_page.webhooks.find(params[:id])
      end

      def webhook_params
        params.require(:webhook).permit(:name, :url, :active, events: [])
      end

      def serialize(webhook, include_secret: false)
        data = {
          id: webhook.id,
          name: webhook.name,
          url: webhook.url,
          events: webhook.event_types,
          active: webhook.active,
          created_at: webhook.created_at.iso8601,
          updated_at: webhook.updated_at.iso8601
        }
        data[:secret_token] = webhook.secret_token if include_secret
        data
      end
    end
  end
end
