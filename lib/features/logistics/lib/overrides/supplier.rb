require_dependency 'lib/features/thirds/app/models/supplier'

class Supplier
  has_many :supplier_supplies
  has_many :supplies, :through => :supplier_supplies
end