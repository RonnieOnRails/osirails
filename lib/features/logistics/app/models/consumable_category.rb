class ConsumableCategory < SupplyCategory
  has_permissions :as_business_object, :class_methods => [:list, :view, :add, :edit, :delete, :disable, :enable]
  has_reference   :prefix => :logistics
  
  has_many :sub_categories, :class_name => "ConsumableSubCategory", :foreign_key => :supply_category_id
end
