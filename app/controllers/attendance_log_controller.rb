class AttendanceLogController < ApplicationController
  def index
    # 勤怠変更申請において、承認されている(status = 2)データを取得
    @approved_data = Change.where("apply_user_id = ? AND status = ?", params[:id], 2).order("date ASC")
    @date = @approved_data.pluck('date').uniq
  end
end