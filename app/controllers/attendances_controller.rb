class AttendancesController < ApplicationController

  def create
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find_by(worked_on: Date.today)
    if @attendance.started_at.nil?
        @attendance.update_attributes(started_at: current_time)
        flash[:info] = 'おはようございます。'
    elsif @attendance.finished_at.nil?
        @attendance.update_attributes(finished_at: current_time)
        flash[:info] = 'おつかれさまでした。'
    else
        flash[:danger] = 'トラブルがあり、登録出来ませんでした。'
    end
    redirect_to @user
  end

  def edit
    unless current_user.admin?
      unless current_user.id == params[:id].to_i
        flash[:danger] = '他人の勤怠ページにはアクセスできません'
        redirect_to root_url
      end
    else
      flash[:danger] = '管理者ユーザはアクセスできません'
      redirect_to root_url
    end
    @user = User.find(params[:id])
    @jousi = User.where(superior: true)
    if current_user.superior?
      @jousi = User.where("superior = ? AND id <> ?", true, current_user.id)
    end
    @first_day = first_day(params[:date])
    @last_day = @first_day.end_of_month
    @dates = user_attendances_month_date
  end

  def update
    @user = User.find(params[:id])
    if attendances_invalid?
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes(item)
      end
      flash[:success] = '勤怠情報を更新しました。'
      redirect_to user_path(@user, params:{first_day: params[:date]})
    else
      flash[:danger] = "不正な時間入力がありました、再入力してください。"
      redirect_to edit_attendances_path(@user, params[:date])
    end
  end

  def changeApply
    if params[:attendances]
      # 指示者確認㊞が選択されている行のみ対象とする
      target = params[:attendances].values.select {|record| record['jousi_id'] != "" and !(Date.current < Date.parse(record['date']))}
      # 上記で取得した行数分ループを行う
      target.each do |validation|
        # バリデーションチェック
        # 出社・退社の時分が全て選択されているか
        if validation['started_at_hour'].present? and validation['started_at_minute'].present? and validation['finished_at_hour'].present? and validation['finished_at_minute'].present?
          # 24時以降で変更のチェックしているか(0 <= 終了時 <= 指定勤務開始時間が24時以降の定義)
          if (Time.parse("00:00") <= Time.parse(validation['finished_at_hour'].to_s + ":" + validation['finished_at_minute'].to_s) and
                Time.parse(validation['finished_at_hour'].to_s + ":" + validation['finished_at_minute'].to_s) <= Time.parse(User.find(params[:id]).designated_work_start_time.to_s)) and
                  validation['changed'] == "0"
            flash[:danger] = '終了時間が0時以降の場合は翌日にチェックしてください。'
            redirect_to edit_attendances_url and return
          end
          # 退社時間 > 出社時間(変更チェックされていることは除く)
          if (Time.parse(validation['date'] + " " + validation['started_at_hour'].to_s + ":" + validation['started_at_minute'].to_s) >=
              Time.parse(validation['date'] + " " + validation['finished_at_hour'].to_s + ":" + validation['finished_at_minute'].to_s)) and validation['changed'] == "0"
            flash[:danger] = Date.parse(validation['date']).to_s(:date).concat('の退社時間 > 出社時間 にするように修正してください。')
            redirect_to edit_attendances_url and return
          end
          # 最近の申請から同じ日に同じ時間(出社,退社とも)に申請していないか
          if Change.select('*')
              .where("apply_user_id = ? AND date = ? AND after_started_at = ? AND after_finished_at = ?",
                params[:id], validation['date'], validation['started_at_hour'] + ":" + validation['started_at_minute'],
                  validation['finished_at_hour'] + ":" + validation['finished_at_minute']).order("id DESC").first
            flash[:danger] = '直近の申請に同じ出社時間と退社時間を申請しないでください。'
            redirect_to edit_attendances_url and return
          end
        else
          flash[:danger] = Date.parse(validation['date']).to_s(:date).concat('の開始・終了を時間と分ともに選んでください。')
          redirect_to edit_attendances_url and return
        end
      end
      # バリデーションクリア
      # もう一回ループ
      target.each do |apply|
        # 対象日付で初めて申請する場合
        unless Change.where("apply_user_id = ? AND date = ?", params[:id], apply['date']).present?
          # 変更申請テーブルを行追加(statusに1(申請中)で固定)
          row = Change.new(apply_user_id: params[:id], date: apply['date'], before_started_at: "", before_finished_at: "", 
                           after_started_at: apply['started_at_hour'] + ":" + apply['started_at_minute'],
                           after_finished_at: apply['finished_at_hour'] + ":" + apply['finished_at_minute'],
                           note: apply['note'], status: 1, approve_user_id: apply['jousi_id'], approve_date: "")
        else
          # 最後に申請したデータを取得し、そのデータをもとに行追加(statusに1(申請中)で固定)
          latestData = Change.select("*").where("apply_user_id = ? AND date = ?", params[:id], apply['date']).order("id desc").first
          row = Change.new(apply_user_id: params[:id], date: apply['date'],
                           before_started_at: latestData.after_started_at, before_finished_at: latestData.after_finished_at,
                           after_started_at: apply['started_at_hour'] + ":" + apply['started_at_minute'],
                           after_finished_at: apply['finished_at_hour'] + ":" + apply['finished_at_minute'],
                           note: apply['note'], status: 1, approve_user_id: apply['jousi_id'], approve_date: "")
        end
        unless row.save
          render 'edit'
        end
      end
      # 更新完了
      flash[:success] = '勤怠変更を申請しました。'
      redirect_to user_url
    end
  end

  private
  
    def attendances_params
      params.permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end

end