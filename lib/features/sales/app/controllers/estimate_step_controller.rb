class EstimateStepController < ApplicationController
  helper :quotes
  
  acts_as_step_controller

  def show
    @quotes = @order.commercial_step.estimate_step.quotes
  end
  
  def edit
    @quotes = @order.commercial_step.estimate_step.quotes
  end
  
  def update
    if @step.update_attributes(params[:estimate_step])
      flash[:notice] = "Les modifications ont été enregistrées avec succès"
    end
    render :action => :edit
  end
end
