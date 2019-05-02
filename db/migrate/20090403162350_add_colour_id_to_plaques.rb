class AddColourIdToPlaques < ActiveRecord::Migration[4.2]
  def self.up
    add_column :plaques, :colour_id, :integer
  end

  def self.down
    remove_column :plaques, :colour_id
  end
end
