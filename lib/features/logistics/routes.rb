ActionController::Routing::Routes.add_routes do |map|
  map.resources :commodities
  map.refresh_measure_commodity 'commodities/refresh_measure', :controller => 'commodities', :action => 'refresh_measure'
  map.resources :commodity_categories
  map.commodities_manager "commodities_manager", :controller => "commodities_manager"
  map.logistics 'logistics', :controller => 'commodities_manager' #default page for products
  map.resources :inventories
  map.resources :commodities_inventories
end
