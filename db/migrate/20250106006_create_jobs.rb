class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :customer_name
      t.string :address, null: false
      t.references :template, foreign_key: true, type: :uuid
      t.references :contractor, foreign_key: true, type: :uuid
      t.boolean :permitted, default: false, null: false
      t.decimal :permit_fee, precision: 10, scale: 2, default: 250.00
      t.datetime :scheduled_start
      t.datetime :scheduled_end
      t.integer :status, default: 0, null: false
      t.string :wave_invoice_id

      t.timestamps
    end

    add_index :jobs, :status
    add_index :jobs, :permitted
    add_index :jobs, [:workspace_id, :status]
  end
end
