class AddIsVerifiedToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :is_verified, :boolean, default: false, null: false
  end

  def self.down
    remove_column :users, :is_verified
  end
end
