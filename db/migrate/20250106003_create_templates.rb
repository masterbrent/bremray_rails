class CreateTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :templates, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.decimal :minimum_price, precision: 10, scale: 2
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :templates, :name
    add_index :templates, :active
    add_index :templates, [:workspace_id, :name], unique: true
  end
end
