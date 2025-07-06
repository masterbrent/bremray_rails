class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.integer :role, default: 0, null: false
      t.string :password_digest, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true, where: "email IS NOT NULL"
    add_index :users, :phone, unique: true, where: "phone IS NOT NULL"
    add_index :users, :role
    add_index :users, :active
  end
end
