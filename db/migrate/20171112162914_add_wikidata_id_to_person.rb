class AddWikidataIdToPerson < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :wikidata_id, :string
  end
end
