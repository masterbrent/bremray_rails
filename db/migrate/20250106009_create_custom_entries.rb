class CreateCustomEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_entries, id: :uuid do |t|
      t.references :job_card, null: false, foreign_key: true, type: :uuid
      t.string :description, null: false
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 10, scale: 2

      t.timestamps
    end
  end
end
