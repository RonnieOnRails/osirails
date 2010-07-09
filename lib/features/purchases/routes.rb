ActionController::Routing::Routes.add_routes do |map|

  map.resources :purchase_requests do |request|
    request.cancel_supply 'cancel_supply/:purchase_request_supply_id', :controller => 'purchase_requests', :action => 'cancel_supply'
    request.cancel 'cancel', :controller => 'purchase_requests', :action => 'cancel'
    request.cancel_form 'cancel_form', :action => "cancel_form", :controller => "purchase_requests" 
  end
  
  map.prepare_for_new 'prepare_for_new' , :controller => 'purchase_orders', :action => 'prepare_for_new'
  
  map.get_supply 'get_supply',  :controller => 'purchase_orders', 
                                    :action => 'get_supply', 
                                    :method => :get
                                      
  map.get_request_supply 'get_request_supply',  :controller => 'purchase_requests', 
                                    :action => 'get_request_supply', 
                                    :method => :get
                                    
  map.auto_complete_for_supply_reference 'auto_complete_for_supply_reference',  :controller => 'purchase_orders', 
                                                                                    :action => 'auto_complete_for_supply_reference', 
                                                                                    :method => :get

  map.auto_complete_for_supplier_name 'auto_complete_for_supplier_name',  :controller => 'purchase_orders', 
                                                                                    :action => 'auto_complete_for_supplier_name', 
                                                                                    :method => :get

  map.resources :purchase_orders do |order|
    order.cancel 'cancel', :controller => 'purchase_orders', :action => 'cancel'
    order.confirm 'confirm', :controller => 'purchase_orders', :action => 'confirm', :conditions => { :method => :put }
    order.resources :parcels do |parcel|
      parcel.alter_status 'alter_status', :controller => 'parcels', :action => 'alter_status'
    end
  end
  
  map.resources :purchase_order_supplies do |order_supply|
    order_supply.cancel 'cancel', :controller => 'purchase_order_supplies', :action => 'cancel'
  end
  
#  map.alter_status 'alter_status/:id', :controller => 'parcels', :action => 'alter_status'
  map.pending_purchase_orders 'pending_purchase_orders', :controller => 'pending_purchase_orders', :action => 'index'
  map.closed_purchase_orders 'closed_purchase_orders', :controller => 'closed_purchase_orders', :action => 'index'
  
  map.purchases 'purchases', :controller => 'pending_purchase_orders', :action => 'index'  # default page for purchases\

end
