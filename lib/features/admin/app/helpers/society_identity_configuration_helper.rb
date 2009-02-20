module SocietyIdentityConfigurationHelper
  
  def display_markup(name, value)
    value ||= ""
    if is_form_view?
      text_field_tag name, value 
    else
      "#{value}"
    end
  end
  
  def working_day(value)
    html = ''
    date = Date::today.beginning_of_week
    7.times do |i|
      html += date.strftime("%A") + "<input name=\"admin_society_identity_configuration_working_day[]\" type=\"checkbox\" value=#{i} "
      html += " checked" if value.include?(i.to_s)
      html += " disabled" unless params[:action] == 'edit'
      html += ">"
      date += 1.day
    end
    html
  end
  
  def choosen_theme(name, value)
    path = "public/themes"
    disabled = (params[:action] != 'edit' ? "disabled " : "")
    
    html = ""
    html << "<select #{disabled}id='#{name}' name='#{name}'>\n"
    Dir.open(path).each do |theme|
      selected = (theme == value ? "selected='selected' " : "" )
      html << "<option #{selected}value='#{theme}'>#{theme}</option>\n" unless theme.start_with?(".")
    end
    html << "</select>\n"
    html
  end
end
