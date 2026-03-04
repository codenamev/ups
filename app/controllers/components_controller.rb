class ComponentsController < ApplicationController
  include Limitable

  before_action :authenticate_user!
  before_action :set_status_page
  before_action :set_component, only: [ :show, :edit, :update, :destroy, :reorder ]
  before_action -> { check_plan_limits(:components) }, only: [:create]

  def index
    @components = @status_page.components.by_position
  end

  def show
  end

  def new
    @component = @status_page.components.build
  end

  def create
    @component = @status_page.components.build(component_params)
    @component.account = Current.account

    if @component.save
      respond_to do |format|
        format.html { redirect_to [ @status_page, @component ], notice: "Component was successfully created." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("component_form", partial: "form", locals: { component: @component }) }
      end
    end
  end

  def edit
  end

  def update
    if @component.update(component_params)
      respond_to do |format|
        format.html { redirect_to [ @status_page, @component ], notice: "Component was successfully updated." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("component_form", partial: "form", locals: { component: @component }) }
      end
    end
  end

  def destroy
    @component.destroy!

    respond_to do |format|
      format.html { redirect_to [ @status_page, :components ], notice: "Component was successfully deleted." }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@component) }
    end
  end

  def reorder
    new_position = params[:position].to_i
    @component.update!(position: new_position)

    # Reorder other components
    @status_page.components.where.not(id: @component.id).each_with_index do |component, index|
      pos = index >= new_position ? index + 2 : index + 1
      component.update!(position: pos) if component.position != pos
    end

    head :ok
  end

  private

  def set_status_page
    @status_page = Current.account.status_pages.find(params[:status_page_id])
  end

  def set_component
    @component = @status_page.components.find(params[:id])
  end

  def component_params
    params.require(:component).permit(:name, :description, :status, :visible, :position)
  end
end
