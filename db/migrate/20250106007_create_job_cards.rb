class CreateJobCards < ActiveRecord::Migration[8.0]
  def change
    create_table :job_cards, id: :uuid do |t|
      t.references :job, null: false, foreign_key: true, type: :uuid
      t.datetime :closed_at

      t.timestamps
    end

    add_index :job_cards, :closed_at
  end
end
