module ThirdsHelper
#  def contextual_search_for_customer
#    contextual_search("Customer", [ "*",
#                                    "legal_form.name",
#                                    "establishments.name",
#                                    "establishments.contacts.*"] )
#  end
#  
#  def contextual_search_for_supplier
#    contextual_search("Supplier", [ "*",
#                                    "activity_sector_reference.code",
#                                    "activity_sector_reference.activity_sector.name",
#                                    "activity_sector_reference.custom_activity_sector.name",
#                                    "legal_form.name",
#                                    "contacts.first_name", 
#                                    "contacts.last_name",
#                                    "iban.*"] )
#  end
  
  def query_td_for_name_in_customer(content)
    content_tag(:td, link_to(content, @query_object), :class => :text)
  end
  alias_method :query_td_for_name_in_supplier, :query_td_for_name_in_customer
  
  def query_td_for_legal_form_name_in_customer(content)
    content_tag(:td, content, :class => :text)
  end
  alias_method :query_td_for_legal_form_name_in_supplier, :query_td_for_legal_form_name_in_customer
  
  def query_td_for_brand_names_in_customer(content)
    content_tag(:td, content, :class => :text)
  end
  
  def query_td_content_for_brand_names_in_customer
    @query_object.brand_names.join(', ')
  end
  
  def query_td_for_head_office_activity_sector_reference_get_activity_sector_name_in_customer(content)
    content_tag(:td, content, :class => :text)
  end
  
  def query_td_for_activity_sector_reference_get_activity_sector_name_in_supplier(content)
    content_tag(:td, content, :class => :text)
  end
end
