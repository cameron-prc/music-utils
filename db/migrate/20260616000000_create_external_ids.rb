class CreateExternalIds < ActiveRecord::Migration[8.1]
  def change
    create_table :external_ids do |t|
      t.references :internal, polymorphic: true, null: false
      t.string :provider, null: false
      t.string :external_id, null: false

      t.timestamps
    end

    add_index :external_ids, [:internal_type, :internal_id, :provider], unique: true, name: "index_external_ids_on_internal_and_provider"
  end
end
