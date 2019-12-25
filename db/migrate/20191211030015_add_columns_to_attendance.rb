class AddColumnsToAttendance < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :apply_finished_at, :string
    add_column :attendances, :overtime_reason, :string
    add_column :attendances, :overtime_approve_user_id, :integer
    add_column :attendances, :approve_status, :integer
    add_column :attendances, :attendance_change_started_at, :string
    add_column :attendances, :attendance_change_finished_at, :string
    add_column :attendances, :attendance_change_approve_user_id, :integer
    add_column :attendances, :attendance_change_approve_status, :integer
  end
end
