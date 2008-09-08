class Commodity < ActiveRecord::Base
    include Permissible
  
  # Relationship
  belongs_to :commodity_category, :counter_cache => true
  
  # Name Scope
  named_scope :activates, :conditions => {:enable => true}
  
  # Validates
  validates_presence_of :name, :fob_unit_price, :unit_mass, :measure, :taxe_coefficient, :message => "ne peut être vide."
  validates_numericality_of :fob_unit_price, :unit_mass, :measure, :taxe_coefficient, :message => "ne peut être des lettres."

  def after_destroy
    self.counter_update(1)
  end
  
  # This method permit to actualize counter_cache if a commodity is disable
  def counter_update(value = -1)
    parent = CommodityCategory.find(self.commodity_category_id)
    CommodityCategory.update_counters(parent.id, :commodities_count => value)
  end
  
  # Check if a resource can be destroy or disable
  def can_destroy?
    #FIXME commande
    false
  end
  
end
