class CreateContractors < ActiveRecord::Migration[8.0]
  def change
    create_table :contractors, id: :uuid do |t|
      t.string :company_name, null: false
      t.string :contact_name
      t.string :phone, null: false
      t.string :email
      t.boolean :active, default: true, null: false
      t.string :access_token

      t.timestamps
    end

    add_index :contractors, :phone, unique: true
    add_index :contractors, :access_token, unique: true
    add_index :contractors, :active
  end
end
