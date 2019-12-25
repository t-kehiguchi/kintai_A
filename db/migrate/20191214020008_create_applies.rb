class CreateApplies < ActiveRecord::Migration[5.1]
  def change
    create_table :applies do |t|
      t.integer :month
      t.integer :apply_user_id
      t.integer :approve_user_id
      t.integer :status

      t.timestamps
    end
  end
end
