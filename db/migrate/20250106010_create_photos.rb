# db/migrate/20250106010_create_photos.rb
class CreatePhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :photos, id: :uuid do |t|
      t.references :job, null: false, foreign_key: true, type: :uuid
      t.string :url, null: false
      t.string :key, null: false
      t.bigint :size, null: false
      t.string :content_type, null: false
      t.string :uploaded_by, null: false
      
      t.timestamps
    end

    add_index :photos, :key, unique: true
    add_index :photos, [:job_id, :created_at]
  end
end
