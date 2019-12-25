class AddColumnsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :month_attendance_from_user_id, :integer
    add_column :users, :months, :integer, array: true
    add_column :users, :month_attendance_approve_status, :integer
  end
end
