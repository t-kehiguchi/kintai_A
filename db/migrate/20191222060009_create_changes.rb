class CreateChanges < ActiveRecord::Migration[5.1]
  def change
    create_table :changes do |t|
      t.integer :apply_user_id
      t.string :date
      t.string :before_started_at
      t.string :before_finished_at
      t.string :after_started_at
      t.string :after_finished_at
      t.string :note
      t.integer :status
      t.integer :approve_user_id
      t.string :approve_date

      t.timestamps
    end
  end
end
