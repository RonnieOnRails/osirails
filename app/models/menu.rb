class Menu < ActiveRecord::Base
  # Relationship
  belongs_to :parent_menu, :class_name =>"Menu", :foreign_key => "parent_id"
  belongs_to :feature
  has_many :menu_permissions, :dependent => :destroy
  has_one :content

  # Plugin
  acts_as_tree :order =>:position
  acts_as_list :scope => :parent_id

  # Accessor
  attr_accessor :parent_array
  
  # Store the ancient parent_id before update parent
  attr_accessor :old_parent_id, :update_parent
  
  # Named scopes
  named_scope :mains, :order => "position" ,:conditions => {:parent_id => nil}
  named_scope :activated, :order => "position", :include => [:feature], :conditions => { 'features.activated' => true}
 
  # Validation Macros
  validates_presence_of :title, :message => "ne peut être vide"
  
  # Callbacks
  after_create :create_permissions
  
  # Includes
  include Permissible::InstanceMethods
  
  def before_update
    if self.update_parent
      @new_parent_id, self.parent_id = self.parent_id, self.old_parent_id
      self.can_has_this_parent?(@new_parent_id)
    end
  end
 
  def after_update
    if self.update_parent
      self.update_parent = false
      self.change_parent(@new_parent_id)
    end
  end
  
  def last_ancestor(menu = self)
    menu.ancestors.size > 0 ? ( menu.ancestors.size == 1 ? menu.parent_menu : last_ancestor(menu.parent_menu) ) : menu
  end
  
  def insert_at_position(position)  
    super(position_in_bounds(position))
  end
  
  # This method permit to change the parent of a item
  # new_parent : represent the new parent            
  def change_parent(new_parent_id,position = nil)
    if self.can_has_this_parent?(new_parent_id) and new_parent_id.to_s != self.parent_id.to_s
      self.remove_from_list
      self.parent_id = new_parent_id
      position.nil? ? self.insert_at : self.insert_at(position)
      self.move_to_bottom if position.nil?
      self.save
    end
  end       
  
  # This method permit to view if a child can have a new_parent
  def can_has_this_parent?(new_parent_id)
    return true if new_parent_id == "" or new_parent_id.nil?
    new_parent = Menu.find(new_parent_id)
    return false if new_parent.id == self.id or new_parent.ancestors.include?(self) or !new_parent.content.nil?
    true
  end
 
  # This method permit to verify if a menu can be delete or not
  def can_delete_menu?
    !base_item? and !has_children?
  end
    
  # This method test if the menu is a Basic item
  def base_item?
    self.name != nil ? true : false
  end
    
  # This method test if the menu has got children
  def has_children?
    self.children.size > 0 ? true : false
  end
    
  # This method test if it possible to move up the menu
  def can_move_up?
    if self.ancestors.size > 0
      self.parent_menu.children.first.position != self.position
    else
      self.self_and_siblings.first.position != self.position
    end
  end
    
  # This method test if it possible to move down  the menu
  def can_move_down?
    if self.ancestors.size > 0
      self.parent_menu.children.last.position != self.position
    else
      self.self_and_siblings.last.position != self.position
    end
  end
    
  # This method return an array with all menus
  # Current_menu_id permit to hide menu in select menu parent
  def self.get_structured_menus(current_menu_id = nil)
    menus = Menu.mains.activated
    parents = []
    root = Menu.new
    root.title = "  "
    root.id = nil
    parents = get_children(menus, current_menu_id, parents)
    parents
  end
    
  private
    # This method insert in the parents the menus   
    def self.get_children(menus, current_menu_id, parents)
      menus.each do |menu|
        unless menu.id == current_menu_id
          parents << menu
          # If the menu has children, the get_children method is call.
          if menu.children.size > 0
            get_children(menu.children, current_menu_id, parents)
          end
        end
      end
      parents
    end
    
    def create_permissions
      Role.find(:all).each do |r|
        MenuPermission.create(:menu_id => self.id, :role_id => r.id)
      end
    end
      
  protected
    # This position permit to return a valide position for a menu.
    def position_in_bounds(position)
      if position < 1 
        1
      elsif position > self.self_and_siblings.size
        puts self.self_and_siblings.size
        self.self_and_siblings.size
      else
        position
      end
    end
end
