class StatusPagesController < ApplicationController
  include Limitable

  before_action :authenticate_user!
  before_action :set_status_page, only: [ :show, :edit, :update, :destroy ]
  before_action -> { check_plan_limits(:status_pages) }, only: [:create]

  def index
    @status_pages = Current.account.status_pages.includes(:components, :incidents)
  end

  def show
    @components = @status_page.components.visible.by_position
    @recent_incidents = @status_page.incidents.limit(5)
  end

  def new
    @status_page = Current.account.status_pages.build
  end

  def create
    @status_page = Current.account.status_pages.build(status_page_params)

    if @status_page.save
      redirect_to @status_page, notice: "Status page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @status_page.update(status_page_params)
      redirect_to @status_page, notice: "Status page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @status_page.destroy!
    redirect_to status_pages_url, notice: "Status page was successfully deleted."
  end

  private

  def set_status_page
    @status_page = Current.account.status_pages.find(params[:id])
  end

  def status_page_params
    params.require(:status_page).permit(:name, :description, :slug)
  end
end
