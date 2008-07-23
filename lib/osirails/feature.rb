module Osirails
  class Feature < ActiveRecord::Base
    serialize :dependencies
    serialize :conflicts
    serialize :business_objects

    validates_uniqueness_of :name

    # we use ' Method_content '  to name ower tabs

    # contains all others features that conflic with current feature  
    attr_reader :installable_conflicts

    # FIXME Maybe we can use the same tab to list  the dependencies of the current feature ? cf.installable activable

    # contains all dependencies of other current feature
    attr_reader :installable_dependencies

    # contains all dependencies of the current feature
    attr_reader :activate_dependencies

    # FIXME Maybe we can use the same tab to list the feature that depend on the current feature? cf.uninstallable & deactivable

    # contains all features that depend on current feature 
    attr_reader :uninstallable_children

    # contains all features that depend on current feature
    attr_reader :deactivate_children


    # contains log concerning installation_script error
    attr_reader :install_log

    # contains log concerning uninstallation_script error
    attr_reader :uninstall_log



    def installed?
      self.installed
    end

    def activated?
      self.activated
    end

    def has_dependencies?
      self.dependencies != nil and self.dependencies.size > 0 ? true : false
    end

    def child_dependencies
      dependencies = []
      Feature.find(:all).each do |feature|
        if feature.has_dependencies?
          feature.dependencies.each do |dependence|
            if dependence[:name] == self.name && dependence[:version].include?(self.version)
              dependencies << {:name => feature.name, :version => feature.version}
            end
          end
        end
      end
      dependencies
    end

    def has_child_dependencies?
      child_dependencies.size > 0
    end

    def has_conflicts?
      self.conflicts != nil and self.conflicts.size > 0 ? true : false
    end

    def able_to_install?
      # Test if the current feature has conflicts or dependencies with other feature
      return true if !has_dependencies? and !has_conflicts?

      # Test if the current feature has a conflict with an installed feature
      @installable_conflicts = []
      if has_conflicts?
        conflicts.each do |conflict|
          if Feature.find(:all, :conditions => ["name=? and version in (?) and installed = 1", conflict[:name], conflict[:version]]).size > 0
            @installable_conflicts << conflict
          end     
        end
      end

      # Test if the current feature is not present in the conflicts list of all other features
      Feature.find(:all, :conditions => ["installed = 1"]).each do |feature|
        if feature.has_conflicts?
          feature.conflicts.each do |conflict|
            if conflict[:name] == self.name and conflict[:version].include?(self.version)
              @installable_conflicts << conflict
            end
          end
        end
      end

      # Test if the current feature's dependencies are installed
      @installable_dependencies = []
      if has_dependencies?
        dependencies.each do |dependence|
          if Feature.find(:all, :conditions => ["name=? and version in (?) and installed = 1", dependence[:name], dependence[:version]]).size == 0
            @installable_dependencies << dependence
          end     
        end
      end
      @installable_conflicts = @installable_conflicts.uniq
      @installable_dependencies = @installable_dependencies.uniq
      @installable_dependencies.size > 0 || @installable_conflicts.size > 0 ? false : true
    end

    def able_to_uninstall?
      @uninstallable_children = []
      if !self.activated? and self.installed?
        self.child_dependencies.each do |child|
          if Feature.find(:all, :conditions =>["name = ? and version in (?) and (activated = 1 or installed = 1)", child[:name], child[:version]]).size > 0
            @uninstallable_children << child
          end
        end
      else
        return false
      end
      @uninstallable_children = @uninstallable_children.uniq
      @uninstallable_children.size > 0 ? false : true
    end

    def able_to_activate?
      @activate_dependencies = []
      return false if !self.installed? or self.activated? 
      self.dependencies.each do |dependence|
        if  Feature.find(:all, :conditions => ["name = ? and version in (?) and activated = 0", dependence[:name], dependence[:version]]).size > 0
          @activate_dependencies << dependence
        end
      end
      @activate_dependencies = @activate_dependencies.uniq
      @activate_dependencies.size > 0 ? false : true
    end 

    def able_to_deactivate?
      @deactivate_children = []
      return false if !self.activated?
      self.child_dependencies.each do |child|
        if  Feature.find(:all, :conditions => ["name = ? and version in (?) and activated = 1", child[:name], child[:version]]).size > 0
          @deactivate_children << child
        end
      end
      @deactivate_children = @deactivate_children.uniq
      @deactivate_children.size > 0 ? false : true
    end

    def enable
      if able_to_activate?
        self.activated = true
        if self.save 
          return true
        end
      end
      false
    end

    def disable
      if able_to_deactivate?
        self.activated = false
        if self.save
          return true
        end
      end
      false
    end

    def install
      @install_log = []
      return false unless self.able_to_install?
      require 'lib/features/'+self.name+'/install.rb'
      if feature_install
        self.installed = true
        if self.save
          return true
        end
      else 
        puts @install_log
        return false
      end
    end

    def uninstall
      @uninstall_log = []
      return false unless self.able_to_uninstall?
      require 'lib/features/'+self.name+'/uninstall.rb'
      if feature_uninstall
        self.installed = false
        if self.save
          return true
        end
      else 
        puts @uninstall_log
        return false
      end
    end

    def check
      # TODO Code the check function: permissions and other
    end

    def display_flash_notice(method) 
      case method
      when "enable"
        message =  self.name + " est activé."    
      when "disable"
        message = self.name +  " est désactivé."  
      when "install"
        message = self.name +  " est installé."     
      when "uninstall"
        message =  self.name +  " est désinstallé"      
      when "remove"
        message = self.name + " est supprimé"
      end 
      return message
    end

    def display_flash_error(method)

      message = ""
      case method

      when "enable"
        message = "Erreur(s) lors de l'activation de " + self.name
        unless self.activate_dependencies.empty?
          message << "<br /><br />Dépendance(s) non activés requise(s): "
          self.activate_dependencies.each do |error|
            message << "<br />" + error[:name] + " [ v:" + error[:version].join(" | v:") +  "]"
          end
        end  

      when "disable" 
        message = "Erreur(s) lors de la désactivation de " + self.name
        unless self.deactivate_children.empty?
          message  << "<br /><br />D'autres modules dépendent de ce module: "
          self.deactivate_children.each do |error|
            message  << "<br />" + error[:name] + " [ v:" + error[:version] + "]"
          end
        end

      when "install" 
        message = "Erreur(s) lors de l'installation de " + self.name
        unless self.installable_dependencies.empty?
          message << "<br /><br />Dépendance(s) non installés requise(s): "
          self.installable_dependencies.each do |error|
            message << "<br />" + error[:name] + " [ v:" + error[:version].join(" | v: ") + "]"
          end
        end

        unless self.installable_conflicts.empty?
          message << "<br />Conflit(s) détecté(s): "
          self.installable_conflicts.each do |error|
            message << "<br />" + error[:name] + " [ v:" + error[:version].join(" | v: ") + "]"
          end
        end

        unless self.install_log.empty?
          self.install_log.each do |error|
            message << "<br />" + error
          end
        end

      when "uninstall"   
        message = "Erreur(s) lors de la désinstallation de " + self.name
        unless self.uninstallable_children.empty?
          message << "<br /><br />D'autres modules dépendent de ce module: "
          self.uninstallable_children.each do |error|
            message << "<br />" + error[:name] + " [v: " + error[:version]+"]"
          end
        end

        unless self.uninstall_log.empty?
          self.uninstall_log.each do |error|
            message << "<br />" + error
          end
        end  

      when "remove"
        message = "Erreur(s) lors de la suppression de "+ self.name
      end
      return message
    end

    def self.able_to_add?
      
    end

    def self.add(options)
      Osirails::FileManager.upload_file(options)
      system("cd " + options[:directory] + " && tar -xzvf " + options[:file]['datafile'].original_filename + " && rm -f " + options[:file]['datafile'].original_filename)
      true
      # TODO Load the feature dynamicaly
    end

    def remove
      return false if self.installed
      system("cd lib/features/ && rm -rf " + self.name) if self.name.grep(/\//).empty? and self.name.grep(/\.\./).empty?
      self.destroy
    end

  end
end
