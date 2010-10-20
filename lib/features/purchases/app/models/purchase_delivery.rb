class PurchaseDelivery < ActiveRecord::Base
  STATUS_PROCESSING_BY_SUPPLIER = 1
  STATUS_SHIPPED                = 2
  STATUS_RECEIVED_BY_FORWARDER  = 3
  STATUS_RECEIVED               = 4
  STATUS_CANCELLED              = 5
  
  has_permissions :as_business_object, :additional_class_methods => [ :cancel ]
  has_reference :prefix => :purchases  
  
  has_many  :purchase_delivery_items
  has_many  :purchase_order_supplies, :through => :purchase_delivery_items
  has_many  :parcels
  
  belongs_to :canceller, :class_name => "User", :foreign_key => :cancelled_by_id
  belongs_to :delivery_document, :class_name => "PurchaseDocument"
  belongs_to :forwarder
  belongs_to :departure
  belongs_to :arrival, :class_name => "Departure"
  
  cattr_accessor :form_labels
  @@form_labels = Hash.new
  @@form_labels[:processing_by_supplier_since]  = "En attente d'expédition depuis le :"
  @@form_labels[:shipped_on]                    = "Expédié le :"
  @@form_labels[:ship_conveyance]                    = "Par :"
  @@form_labels[:previsional_delivery_date]     = "Date de livraison prévue du colis :"
  @@form_labels[:received_by_forwarder_on]      = "Reçu par le transitaire le :"
  @@form_labels[:awaiting_pick_up]              = "Récupération chez le transitaire :"
  @@form_labels[:received_on]                   = "Reçu le :"
  @@form_labels[:purchase_document]             = "Bon de livraison :"
  @@form_labels[:cancelled_comment]             = "Veuillez saisir la raison de l'annulation :"
  
  validates_date :processing_by_supplier_since, :on_or_before => Date::today,
                                                :on_or_before_message  => :message_for_processing_by_supplier_since_on_or_before_today,
                                                :if => :processing_by_supplier?
  validates_date :shipped_on, :on_or_after => :processing_by_supplier_since,
                              :on_or_after_message  => :message_for_shipped_on_or_after_processing_by_supplier_since,
                              :if => :shipped?
  validates_date :shipped_on, :on_or_before => Date::today,
                              :on_or_before_message  => :message_for_shipped_on_or_before_today,
                              :if => :shipped?
  validates_date :received_by_forwarder_on, :on_or_after => :processing_by_supplier_since,
                                            :on_or_after_message  => :message_for_received_by_forwarder_on_or_after_processing_by_supplier_since,
                                            :if => :received_by_forwarder?
  validates_date :received_by_forwarder_on, :on_or_after => :shipped_on,
                                            :on_or_after_message  => :message_for_received_by_forwarder_on_or_after_shipped_on,
                                            :if => :received_by_forwarder?
  validates_date :received_by_forwarder_on, :on_or_before => Date::today,
                                            :on_or_before_message  => :message_for_received_by_forwarder_on_or_before_today,
                                            :if => :received_by_forwarder?
  validates_date :received_on, :on_or_after => :processing_by_supplier_since,
                                :on_or_after_message  => :message_for_received_on_or_after_processing_by_supplier_since,
                                :if => :received?
  validates_date :received_on, :on_or_after => :shipped_on,
                                :on_or_after_message  => :message_for_received_on_or_after_shipped_on,
                                :if => :received?  
  validates_date :received_on, :on_or_after => :received_by_forwarder_on,
                                :on_or_after_message  => :message_for_received_on_or_after_received_by_forwarder_on,
                                :if => :received?
  validates_date :received_on, :on_or_before => Date::today,
                                :on_or_before_message  => :message_for_received_on_or_before_today,
                                :if => :received?
  
  validates_presence_of :ship_conveyance , :if => :shipped?, :message => "Veuillez renseigner le transport."
  validates_presence_of :cancelled_comment, :if => :cancelled_at, :message => "Veuillez indiquer la raison de l'annulation."
  validates_presence_of :reference
  validates_presence_of :canceller, :if => :cancelled_by_id
  
  validates_inclusion_of :status, :in => [ STATUS_PROCESSING_BY_SUPPLIER, STATUS_SHIPPED, STATUS_RECEIVED_BY_FORWARDER, STATUS_RECEIVED ], :if => :new_record?
  validates_inclusion_of :status, :in => [ STATUS_PROCESSING_BY_SUPPLIER, STATUS_SHIPPED, STATUS_RECEIVED_BY_FORWARDER , STATUS_RECEIVED, STATUS_CANCELLED ], :if => :was_processing_by_supplier?
  validates_inclusion_of :status, :in => [ STATUS_SHIPPED, STATUS_RECEIVED_BY_FORWARDER, STATUS_RECEIVED, STATUS_CANCELLED ], :if => :was_shipped?
  validates_inclusion_of :status, :in => [ STATUS_RECEIVED_BY_FORWARDER, STATUS_RECEIVED, STATUS_CANCELLED], :if => :was_received_by_forwarder?
  validates_inclusion_of :status, :in => [ STATUS_RECEIVED ], :if => :was_received?   
  
  validates_persistence_of :shipped_on,                 :if => :shipped_on_was
  validates_persistence_of :ship_conveyance,            :if => :ship_conveyance_was
  validates_persistence_of :previsional_delivery_date,  :if => :previsional_delivery_date_was
  validates_persistence_of :received_by_forwarder_on,   :if => :received_by_forwarder_on_was
  validates_persistence_of :awaiting_pick_up,           :if => :awaiting_pick_up_was
  validates_persistence_of :received_on,                :if => :received_on_was
  validates_persistence_of :cancelled_comment,          :if => :cancelled_at_was  
  
  validates_associated :purchase_delivery_items
  validates_associated :delivery_document, :if => :received_on
  validate :validates_lenght_of_purchase_delivery_item_selected, :if => :new_record?
  
  before_validation_on_create :update_reference, :free_purchase_delivery_item_unselected
  
  after_save  :automatically_put_purchase_order_status_to_processing_by_supplier#, :save_associated_purchase_delivery_items
  after_save  :save_delivery_document, :if => :received?
  
  def free_purchase_delivery_item_unselected
    self.purchase_delivery_items = self.purchase_delivery_items.select(&:selected?)
  end
  
  def save_associated_purchase_delivery_items
    for purchase_delivery_item in purchase_delivery_items
      purchase_delivery_item.save(false) if purchase_delivery_item.selected?
    end
  end
  
  def purchase_order
    self.purchase_delivery_items.first.purchase_order_supply.purchase_order if self.purchase_delivery_items.first
  end
  
  def automatically_put_purchase_order_status_to_processing_by_supplier
    self.purchase_order.process_by_supplier unless self.purchase_order.was_processing_by_supplier?
  end
  
  def validates_lenght_of_purchase_delivery_item_selected
    result = 0;
    for purchase_delivery_item in purchase_delivery_items
      result += purchase_delivery_item.selected.to_i
    end
    errors.add(:purchase_delivery_items, I18n.t("activerecord.errors.models.purchase_delivery.attributes.purchase_delivery_items.presence_of", :restriction => "")) if result == 0
  end
  
  def delete_unselected_purchase_delivery_items
    for purchase_delivery_item in purchase_delivery_items
      purchase_delivery_item.destroy if purchase_delivery_item.selected.to_i == 0
    end
  end
  
  def processing_by_supplier?
    status == STATUS_PROCESSING_BY_SUPPLIER
  end
  
  def shipped?
    status == STATUS_SHIPPED
  end
  
  def received_by_forwarder?
    status == STATUS_RECEIVED_BY_FORWARDER
  end
  
  def received?
    status == STATUS_RECEIVED
  end
  
  def cancelled?
    new_record? ? false : ( purchase_delivery_items.count == purchase_delivery_items.select{ |pi| pi.cancelled? }.size ? true : ( status == STATUS_CANCELLED ) )
  end
  
  def was_processing_by_supplier?
    status_was == STATUS_PROCESSING_BY_SUPPLIER
  end
  
  def was_shipped?
    status_was == STATUS_SHIPPED
  end
  
  def was_received_by_forwarder?
    status_was == STATUS_RECEIVED_BY_FORWARDER
  end
  
  def was_received?
    status_was == STATUS_RECEIVED
  end
  
  def was_cancelled?
    new_record? ? false : (purchase_delivery_items.count == purchase_delivery_items.select{ |pi| pi.was_cancelled? }.size ? true : ( status_was == STATUS_CANCELLED ) )
  end
  
  def can_be_processed_with_associated_purchase_delivery_items?
    purchase_delivery_items.each{ |pi| return false if(pi.quantity > pi.purchase_order_supply.remaining_quantity_for_purchase_delivery) }
    true
  end
  
  def can_be_processed_by_supplier?
    new_record?
  end
  
  def can_be_shipped?
    (was_processing_by_supplier? and !was_cancelled? and !was_shipped?) || (was_processing_by_supplier? and !was_cancelled?)
  end
  
  def can_be_received_by_forwarder?
    (was_shipped? || can_be_shipped?) and !was_cancelled? and !was_received_by_forwarder?
  end
  
  def can_be_received?
    (new_record? || was_received_by_forwarder? || can_be_received_by_forwarder?) and !was_cancelled? and !was_received?
  end
  
  def can_be_cancelled?
    (!was_cancelled? and !new_record? and !was_received?) || can_be_received?
  end
  
  def process_by_supplier
    if can_be_processed_by_supplier?
      self.status = STATUS_PROCESSING_BY_SUPPLIER
      return self.save
    end
    false
  end
  
  def ship
    if can_be_shipped?
      self.status = STATUS_SHIPPED
      return self.save
    end
    false
  end
  
  def receive_by_forwarder
    if can_be_received_by_forwarder?
      self.status = STATUS_RECEIVED_BY_FORWARDER
      return self.save
    end
    false
  end
  
  def receive
    if can_be_received?
      self.status = STATUS_RECEIVED
      return self.save
    end
    false
  end
  
  def cancel
    if can_be_cancelled?
      self.cancelled_at = Time.now
      self.status = STATUS_CANCELLED
      return self.save
    end
    false
  end
  
  def purchase_delivery_item_attributes=(purchase_delivery_item_attributes)
    purchase_delivery_item_attributes.each do |attributes|
      purchase_delivery_items.build(attributes) if attributes[:purchase_order_supply_id]
    end
  end
  
  def build_purchase_delivery_items_with_purchase_order_supplies(purchase_order_supplies)
    for purchase_order_supply in purchase_order_supplies
      if !purchase_order_supply.cancelled? && purchase_order_supply.remaining_quantity_for_purchase_delivery != 0 &&
         !purchase_delivery_items.detect { |t| t.purchase_order_supply_id == purchase_order_supply.id } 
         purchase_delivery_items.build(:purchase_order_supply_id => purchase_order_supply.id, :quantity => purchase_order_supply.remaining_quantity_for_purchase_delivery, :selected => 0)
      end
    end
    purchase_delivery_items
  end
  
  def delivery_document_attributes=(delivery_document_attributes)
    self.delivery_document = PurchaseDocument.new(delivery_document_attributes.first)
  end
  
  def save_delivery_document
    delivery_document.save
  end
  
  def message_for_processing_by_supplier_since_on_or_before_today 
    message_for_validates_date("processing_by_supplier_since", "on_or_before", Date.today)
  end
  
  def message_for_shipped_on_or_after_processing_by_supplier_since
    message_for_validates_date("shipped_on", "on_or_after", self.processing_by_supplier_since)
  end 
  
  def message_for_shipped_on_or_before_today 
    message_for_validates_date("shipped_on", "on_or_after", Date.today)  
  end 
  
  def message_for_received_by_forwarder_on_or_after_processing_by_supplier_since
     message_for_validates_date("received_by_forwarder_on", "on_or_after", self.processing_by_supplier_since)
  end 
  
  def message_for_received_by_forwarder_on_or_after_shipped_on
    message_for_validates_date("received_by_forwarder_on", "on_or_after", self.shipped_on) 
  end 
  
  def message_for_received_by_forwarder_on_or_before_today 
    message_for_validates_date("received_by_forwarder_on", "on_or_before", Date.today)
  end 
  
  def message_for_received_on_or_after_processing_by_supplier_since
    message_for_validates_date("received_on", "on_or_after", self.processing_by_supplier_since)
  end
    
  def message_for_received_on_or_after_shipped_on 
    message_for_validates_date("received_on", "on_or_after", self.shipped_on)
  end 
  
  def message_for_received_on_or_after_received_by_forwarder_on 
    message_for_validates_date("received_on", "on_or_after", self.received_by_forwarder_on)
  end
  
  def message_for_received_on_or_before_today
    message_for_validates_date("received_on", "on_or_before", Date.today) 
  end
  
  private
    def message_for_validates_date(attribute, error_type, restriction)
      I18n.t("activerecord.errors.models.purchase_delivery.attributes.#{attribute}.#{error_type}", :restriction => restriction)
    end
end