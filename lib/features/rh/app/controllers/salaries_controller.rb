class SalariesController < ApplicationController
  
  # GET /employees/:employee_id/index
  def index
    @employee = Employee.find(params[:employee_id])
    @salaries = @employee.job_contract.salaries
  end
  
end
