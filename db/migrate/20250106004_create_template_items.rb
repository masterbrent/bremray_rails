class CreateTemplateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :template_items, id: :uuid do |t|
      t.references :template, null: false, foreign_key: true, type: :uuid
      t.references :master_item, null: false, foreign_key: true, type: :uuid
      t.integer :default_quantity, default: 0, null: false

      t.timestamps
    end

    add_index :template_items, [:template_id, :master_item_id], unique: true
  end
end
