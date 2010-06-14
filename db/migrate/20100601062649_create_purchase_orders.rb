class CreatePurchaseOrders < ActiveRecord::Migration
  def self.up
    create_table  :purchase_orders do |t|
      t.integer   :user_id
      t.integer   :supplier_id
      t.integer   :cancelled_by
      t.integer   :invoice_document_id
      t.integer   :delivery_document_id
      t.integer   :quotation_document_id
      t.integer   :payment_document_id
      t.integer   :payment_method_id

      t.string    :reference
      t.string    :status
      t.string    :cancelled_comment
      t.boolean   :paid
      
      t.datetime  :confirmed_at
      t.datetime  :processing_since
      t.datetime  :completed_at
      t.datetime  :cancelled_at
      t.timestamps
    end
  end

  def self.down
    drop_table :purchase_orders
  end
end
