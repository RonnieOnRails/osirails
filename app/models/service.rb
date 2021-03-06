class Service < ActiveRecord::Base
  has_permissions :as_business_object
  
  acts_as_tree :order => :name, :foreign_key => "service_parent_id"
  
  has_many :employees
  has_many :schedules
  has_many :jobs
  
  named_scope :mains,:conditions => {:service_parent_id => nil}
  
  validates_presence_of :name
  
  # Store the ancient services_parent_id before update_service_parent
  attr_accessor :old_service_parent_id, :update_service_parent
  cattr_accessor :form_labels
  
  # FIXME is this comment usefull? the bug should be resolved in last rails version
  # relationships 'parent' was commented because of a bug (when introducing relationships permitting to model to refer to them self)
  # => there's two different behavior according to the RAISL_ENV
  # dev : it works but it's a question of luck
  # prod : it don't work and it permit to see a problem with this kind of relationships into :include array passed to 'find' method
  # this difference come from the relationships order into the include array
  # ps : the problem occur when including service to perform a find into employee for example it works if just searching from service
  has_search_index :only_attributes       => [:name],
                   :except_relationships  => [:schedules, :parent, :children, :employees_services, :employees]

  @@form_labels = Hash.new
  @@form_labels[:name]           = "Nom :"
  @@form_labels[:service_parent] = "Service parent :"

  # Method to get all responsibles for the service (it return employees)
  def responsibles
    responsibles_employees = []
    self.jobs.reject {|n| n.responsible == false}.each do |job|
      responsibles_employees += job.employees
    end
    return responsibles_employees.uniq
  end
  
  # Method that return all employees that belongs to current service according to the belonging jobs or the belonging employees
  def members
    Employee.all(:include => [:service, {:jobs => [:service] }], :conditions => ["services.id =? or services_jobs.id =?", id, id])
  end
  
  # This method permit to check if a service can be a parent
  def before_update
    if self.update_service_parent
      if self.service_parent_id == nil
        true
      else
        new_parent_id, self.service_parent_id = self.service_parent_id, self.old_service_parent_id
        @new_parent = Service.find(new_parent_id)
        return false if @new_parent.id == self.id  or @new_parent.ancestors.include?(self)
        true
      end
    end
  end
  
  # This method apply configuration when before update return true
  def after_update
    if self.update_service_parent
      self.update_service_parent = false
      if self.service_parent_id == nil
        self.service_parent_id = nil
      else
        self.service_parent_id = @new_parent.id
        self.save
      end
    end
  end
  
  def can_be_destroyed?
    self.children.empty?
  end
  
  # method to return the params[:schedules] hash completed with the form values 
  def get_time(day,chaine)
  
    schedules = chaine.split("|")
    formated_schedules = []
    schedules_hash = {}
    
    schedules.each_with_index do |f,index|
      value = f.split(' H ')

      value==[] ? tmp = nil : tmp = value[0].to_i  
      tmp.nil? ? tmp = nil : tmp += value[1].to_i.minutes.to_f / 3600

      formated_schedules << tmp
    end
    
    schedules_hash[:day] = Time::R_DAYS[day]
    schedules_hash[:morning_start] = formated_schedules[0]
    schedules_hash[:morning_end] = formated_schedules[1]
    schedules_hash[:afternoon_start] = formated_schedules[2]
    schedules_hash[:afternoon_end] = formated_schedules[3]
    
    return schedules_hash
  end
  
  def schedule_find (service=self)
    while !service.parent.nil?
      if service.schedules == []
        service = service.parent
      else
        return service
      end
    end
    return service 
  end
  
  # This method permit to have structur for services
  def self.get_structured_services(current_service_id = nil)
    services = Service.find_all_by_service_parent_id
    service_parents = []
    root = Service.new
    root.name = "  "
    root.id = nil
    get_children(services, current_service_id, service_parents)
  end
  
  private
    # This method permit to have children for services
    def self.get_children(services, current_service_id, service_parents)
      services.each do |service|
        unless service.id == current_service_id
          service_parents << service
          if service.children.size > 0
            get_children(service.children, current_service_id , service_parents)
          end
        end
      end
      service_parents
    end
  
end
