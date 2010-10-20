class CreatePurchaseRequestSupplies < ActiveRecord::Migration
  def self.up
    create_table :purchase_request_supplies do |t|
      t.references  :purchase_request, :supply, :cancelled_by, :purchase_priority
      t.integer     :expected_quantity
      t.string      :designation
      t.text        :comment
      t.datetime    :cancelled_at
      t.date        :expected_delivery_date
      
      t.timestamps
    end
  end

  def self.down
    drop_table :purchase_request_supplies
  end
end