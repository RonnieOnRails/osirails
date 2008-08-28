# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def file_upload
    file_field 'upload', 'datafile'
  end
  
  def display_flash
    html = ""
    flash.each_pair do |key, value|
      html << '<br/>' unless html == ""
      html << "<span class=\"flash_#{key}\"><span>#{value}</span></span>"
    end
    html == "" ? "" : "<div class=\"flash_container\">" << html << "</div>"
  end
  
  def current_user
    session[:user]
  end
  
  def current_menu
    Menu.find_by_name(controller.controller_name) or raise "The controller '#{controller.controller_name}' should have a menu with the same name"
  end
  
  def url_for_menu(menu)
    # OPTIMIZE optimize this IF block code
    if menu.name
      path = menu.name + "_path"
      if self.respond_to?(path)
        self.send(path)
      else
        url_for(:controller => menu.name)
      end
    else
      # FIXME when the menu is linked with a Content, link to the Content
      ""
    end
  end
  
  def display_main_menu
    html = ""
    menu = current_menu
    Menu.mains.each do |m|
      selected = (menu == m or menu.ancestors.include?(m) ? "class=\"selected\"" : "")
      html << "<li #{selected} title=\"#{m.description}\">#{link_to(m.title, url_for_menu(m))}</li>\n"
    end
    html
  end
  
  def display_second_menu
    html = []
    menu = current_menu
    main_menu = menu.last_ancestor
    #return if main_menu.nil?
    main_menu.children.each do |m|
      first = main_menu.children.first == m ? "id=\"menu_horizontal_first\"": "" #detect if is the first element
      selected = ( ( menu == m or menu.ancestors.include?(m) ) ? "class=\"selected\"" : "") #detect if the element is selected
      html << link_to("<span title=\"#{m.description}\" #{selected} #{first}>#{m.title}</span>", url_for_menu(m))
    end
    html.reverse.to_s
  end
  
  def display_tabulated_menu
    html = "<div class=\"tabs\"><ul>"
    menu = current_menu
    menu.self_and_siblings.each do |m|
      selected = ( m == menu ? "class=\"selected\"" : "" )
      html << "<li #{selected}>" + link_to(m.title, url_for_menu(m)) + "</li>"
    end
    html << "</ul></div>"
  end
  
  def display_welcome_message
    "Bienvenue, " + ( current_user ? ( current_user.employee ? "#{current_user.employee.fullname}" : "\"#{current_user.username}\"" ) : "" )
  end
  
  def display_date_time
    day = DateTime.now.strftime("%A").downcase
    DateTime.now.strftime("Nous sommes le #{day} %d %B %Y, il est %H:%M")
  end
  
  def my_text_field_with_auto_complete(object, method, tag_options = {}, completion_options = {})
    if(tag_options[:index])
      tag_name = "new_#{object}#{tag_options[:index]}_#{method}"
    else
      tag_name = "new_#{object}#{method}"
    end
    (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
      
#        text_field(object, method, tag_options) +
        content_tag("input", "", :id => "new_#{object}#{tag_options[:index]}_#{method}", :type => "text", :size => 30, 
        :name => "new_#{object}#{tag_options[:index]}[#{method}]", :autocomplete => "off") +
        content_tag("div", "", :id => tag_name + "_auto_complete", :class => "auto_complete") +
        auto_complete_field(tag_name, { :url => {:controller => "#{tag_options[:url][:controller]}", :action => "auto_complete_for_#{object}_#{method}", :country_id => tag_options[:country_id]} }.update(completion_options))
                                                                
  end
end
