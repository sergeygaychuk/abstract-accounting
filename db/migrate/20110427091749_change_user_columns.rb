class ChangeUserColumns < ActiveRecord::Migration
  def self.up
    remove_column :users, :username
    add_column :users, :entity_id, :integer
  end

  def self.down
    remove_column :users, :entity_id
    add_column :users, :username, :string
  end
end
