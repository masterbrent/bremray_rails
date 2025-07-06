class CreateMasterItems < ActiveRecord::Migration[8.0]
  def change
    create_table :master_items, id: :uuid do |t|
      t.string :code, null: false
      t.string :description, null: false
      t.decimal :base_price, precision: 10, scale: 2, null: false
      t.string :category
      t.string :unit, default: 'each', null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :master_items, :code, unique: true
    add_index :master_items, :category
    add_index :master_items, :active
  end
end
