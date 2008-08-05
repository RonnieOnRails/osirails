module MenusHelper
  
  # This method permit to show or not show a button for up a menu
  def show_up_button(menu)
    link_to(image_tag("url", :alt =>"Monter"), { :action => "move_up", :id => menu.id }) if menu.can_move_up?
  end
  
   # This method permit to show or not show a button for down a menu
  def show_down_button(menu)
    link_to(image_tag("url", :alt => "Descendre"), { :action => "move_down", :id => menu.id }) if menu.can_move_down?
  end
  
  # This method permit to show or not show a button for delete a menu
  def show_delete_button(menu)
    " &#124; " + link_to("Supprimer", menu, {:method => :delete, :confirm => 'Etes vous sûr de vouloir supprimer cette page ?' }) unless menu.base_item?
  end
end
