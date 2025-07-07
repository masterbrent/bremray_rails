class CreateJobItems < ActiveRecord::Migration[8.0]
  def change
    create_table :job_items, id: :uuid do |t|
      t.references :job_card, null: false, foreign_key: true, type: :uuid
      t.references :master_item, null: false, foreign_key: true, type: :uuid
      t.integer :quantity, default: 0, null: false

      t.timestamps
    end

    add_index :job_items, [:job_card_id, :master_item_id], unique: true
  end
end
