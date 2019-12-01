class CreateBases < ActiveRecord::Migration[5.1]
  def change
    create_table :bases do |t|
      t.integer :baseNo
      t.string :baseName
      t.string :attendanceKind

      t.timestamps
    end
  end
end
