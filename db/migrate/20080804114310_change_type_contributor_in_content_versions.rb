class ChangeTypeContributorInContentVersions < ActiveRecord::Migration
  def self.up
    remove_column :content_versions, :contributor
    add_column :content_versions, :contributor_id, :integer
  end

  def self.down
    remove_column :contents, :contributor_id
    add_column :contents, :contributor, :string    
  end
end
