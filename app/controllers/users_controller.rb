class UsersController < ApplicationController

  before_action :logged_in_user, only: [:index, :show, :edit, :update]
  before_action :correct_user,   only: :edit
  before_action :admin_user,     only: [:destroy, :edit_basic_info, :update_basic_info]
  before_action :admin_or_incorrect_user, only: :show

  def index
    unless current_user.admin?
      unless current_user.id == params[:id].to_i
        flash[:danger] = '一般ユーザはアクセスできません'
        redirect_to root_url
      end
    end
    if params[:name]
      @users = user_search(params[:name]).paginate(page: params[:page])
    else
      @users = User.paginate(page: params[:page])
    end
  end

  def show
    if params[:designMode]
      @designMode = true
    end
    @user = User.find(params[:id])
    @jousi = User.where("superior = ? AND id <> ?", true, params[:id])
    @first_day = first_day(params[:first_day])
    @last_day = @first_day.end_of_month
    (@first_day..@last_day).each do |day|
      unless @user.attendances.any? {|attendance| attendance.worked_on == day}
        record = @user.attendances.build(worked_on: day)
        record.save
      end
    end
    @dates = user_attendances_month_date
    @worked_sum = @dates.where.not(started_at: nil).count
    # 残業申請、勤怠変更申請、月申請のそれぞれ上司に申請がきているか取得(statusの1は「申請中」)
    @overtime_request = Attendance.where("overtime_approve_user_id = ? AND approve_status = ?", params[:id], 1)
    @overtime_request_uniq = @overtime_request.pluck(:user_id).uniq
    @change_request = Change.where("approve_user_id = ? AND status = ?", params[:id], 1)
    @change_request_uniq = @change_request.pluck(:apply_user_id).uniq
    @month_request = Apply.where("status = ? AND approve_user_id = ?", 1, params[:id])
    @month_request_uniq = @month_request.pluck(:apply_user_id).uniq
    @month_current_user_request = Apply.find_by(month: Date.parse(@first_day.to_s).month, apply_user_id: params[:id])
    # 残業申請が承認 or 否認されているデータ(approve_statusは2,3)
    @overtime_approved_or_denied = Attendance.where(approve_status: [2,3], user_id: params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in(@user)
      flash[:success] = "ユーザーの新規作成に成功しました。"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    # @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      # 更新に成功した場合の処理
      flash[:success] = 'ユーザー情報を更新しました。'
      redirect_to users_url
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = '削除しました。'
    redirect_to users_url
  end

  def edit_basic_info
    @user = User.find(params[:id])
  end

  def update_basic_info
    @user = User.find(params[:id])
    @users = User.all
    @users.each do |user|
      unless user.update_attributes(basic_info_params)
        render 'edit_basic_info'
      end
    end
    flash[:success] = "基本情報を更新しました。"
    redirect_to @user
  end

  def import
    # fileはtmpに自動で一時保存される
    User.import(params[:file])
    redirect_to users_url
  end

  def export
    @first_day = first_day(params[:date])
    @last_day = @first_day.end_of_month
    @export_data = Attendance.where("worked_on BETWEEN ? AND ? AND user_id = ?", @first_day, @last_day, params[:id]).order("worked_on ASC")
    respond_to do |format|
      format.html
      format.csv do |csv|
        send_posts_csv(@export_data)
      end
    end
  end

  def working
    @workingMembers = User.joins(:attendances).where("worked_on = ? and started_at is not null and finished_at is null", Date.today)
  end

  def monthApply
    # 申請先上司を選んでいるか
    if params[:jousi_id].empty?
      flash[:danger] = '上司を選んでください'
      redirect_to user_url and return
    end
    # 申請テーブルに挿入(statusに1(申請中)で固定)
    apply = Apply.new(month: params[:month], apply_user_id: params[:id], approve_user_id: params[:jousi_id], status: 1)
    if apply.save
      flash[:success] = User.find(params[:jousi_id]).name + 'に申請しました。'
      redirect_to user_url
    else
      render 'show'
    end
  end

  def monthApprove
    if params[:applies]
      # 変更をチェックしているか(1件でもチェックしていないならエラーにする仕様)
      if params[:applies].values.find {|status| status['changed'] == "0"}
        flash[:danger] = '変更をチェックしてから送信してください。'
        redirect_to user_url and return
      end
      # 申請行の件数分ループ
      params[:applies].values.each do |apply|
        row = Apply.find_by(month: apply['month'], apply_user_id: apply['apply_from_user_id'], approve_user_id: params[:id])
        row.status = apply['status']
        unless row.save
          render 'show'
        end
      end
      # 更新完了
      flash[:success] = '申請ステータスを更新しました。'
      redirect_to user_url
    end
  end

  def zangyouApply
    # 申請先上司を選んでいるか
    if params[:jousi_id].empty?
      flash[:danger] = '上司を選んでください。'
      redirect_to user_url and return
    # 終了時間が選択されているか(両方とも)
    elsif params[:finished_at_hour].empty? or params[:finished_at_minute].empty?
      flash[:danger] = '終了時間を時間と分ともに選んでください。'
      redirect_to user_url and return
    # 24時以降で変更のチェックしているか(0 <= 終了時 <= 指定勤務開始時間が24時以降の定義)
    elsif (Time.parse("00:00") <= Time.parse(params[:finished_at_hour].to_s + ":" + params[:finished_at_minute].to_s) and
            Time.parse(params[:finished_at_hour].to_s + ":" + params[:finished_at_minute].to_s) <= Time.parse(User.find(params[:id]).designated_work_start_time)) and params[:changed] == "0"
      flash[:danger] = '終了時間が0時以降の場合は翌日にチェックしてください。'
      redirect_to user_url and return
    # そもそも出社時間なしで残業申請できない
    elsif !(Attendance.find_by(worked_on: params[:date], user_id: params[:id]).started_at.present?)
      flash[:danger] = '出社時間がある場合のみ残業申請できます。'
      redirect_to user_url and return
    end
    # 勤怠テーブルを更新(statusに1(申請中)で固定)
    attendance = Attendance.find_by(worked_on: params[:date], user_id: params[:id])
    attendance.apply_finished_at = params[:finished_at_hour].to_s.concat(":").concat(params[:finished_at_minute].to_s)
    attendance.overtime_reason = params[:note]
    attendance.overtime_approve_user_id = params[:jousi_id]
    attendance.approve_status = 1
    # 残業申請成功
    if attendance.save
      flash[:success] = User.find(params[:jousi_id]).name + 'に申請しました。'
      redirect_to user_url
    else
      render 'show'
    end
  end

  def zangyouApprove
    if params[:zangyous]
      # 変更をチェックしているか(1件でもチェックしていないならエラーにする仕様)
      if params[:zangyous].values.find {|status| status['changed'] == "0"}
        flash[:danger] = '変更をチェックしてから送信してください。'
        redirect_to user_url and return
      end
      # 申請行の件数分ループ
      params[:zangyous].values.each do |zangyou|
        row = Attendance.find_by(worked_on: zangyou['date'], user_id: zangyou['apply_from_user_id'].to_i, overtime_approve_user_id: params[:id])
        row.approve_status = zangyou['status']
        # 承認の場合は退社時間も更新
        if zangyou['status'].present? and zangyou['status'].to_i == 2
          row.finished_at = row.apply_finished_at
        end
        unless row.save
          render 'show'
        end
      end
      # 更新完了
      flash[:success] = '申請ステータスを更新しました。'
      redirect_to user_url
    end
  end

  def changeApprove
    if params[:changes]
      # 変更をチェックしているか(1件でもチェックしていないならエラーにする仕様)
      if params[:changes].values.find {|status| status['changed'] == "0"}
        flash[:danger] = '変更をチェックしてから送信してください。'
        redirect_to user_url and return
      end
      # 申請行の件数分ループ
      params[:changes].values.each do |change|
        row = Change.find_by(apply_user_id: change['apply_from_user_id'], date: change['date'],
          before_started_at: change['before_started_at'], before_finished_at: change['before_finished_at'],
            after_started_at: change['after_started_at'], after_finished_at: change['after_finished_at'], approve_user_id: params[:id])
        row.status = change['status']
        # 承認の場合は承認日(実行日)も更新
        if row.status == 2
          # row.status = change['status'].to_i
          row.approve_date = Time.zone.now.strftime("%Y-%m-%d")
        end
        unless row.save
          render 'show'
        end
        # さらにAttendanceテーブルにも更新
        attendance = Attendance.find_by(worked_on: change['date'], user_id: change['apply_from_user_id'])
        # 終了時間が0時以降(0 <= 終了時 <= 指定勤務開始時間)の場合
        if Time.parse("00:00") <= Time.parse(change['after_finished_at'].to_s) and
            Time.parse(change['after_finished_at'].to_s) <=
              Time.parse(User.find(change['apply_from_user_id']).designated_work_start_time.to_s)
          attendance.finished_at = Time.zone.parse(change['date'] + " " + row.after_finished_at.to_s).to_datetime + 1
        else
          attendance.finished_at = Time.zone.parse(change['date'] + " " + row.after_finished_at.to_s).to_datetime
        end
        attendance.started_at = Time.zone.parse(change['date'] + " " + row.after_started_at.to_s).to_datetime
        attendance.note = row.note
        unless attendance.save
          render 'show'
        end
      end
      # 更新完了
      flash[:success] = '申請ステータスを更新しました。'
      redirect_to user_url
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :password, :password_confirmation, :employee_number, :uid, :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end
    
    def basic_info_params
      params.require(:user).permit(:basic_time, :work_time)
    end
    
    def user_search(name)
      @users = User.where(['name LIKE ?', "%#{name}%"])
    end

    # beforeアクション

    # ログイン済みユーザーか確認
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "ログインしてください。"
        redirect_to login_url
      end
    end

    # 正しいユーザーかどうか確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless curent_user?(@user)
    end

     # 管理者かどうかを確認
    def admin_user
      redirect_to(root_url) if !current_user.admin?
    end

    def admin_or_incorrect_user
      if current_user.admin? or ( current_user.id != params[:id].to_i )
        unless params[:designMode]
          flash[:danger] = "勤怠ページにはアクセスできません"
          redirect_to root_url
        end
      end
    end

    def send_posts_csv(export_data)
      bom = "\uFEFF"
      csv_data = CSV.generate(bom) do |csv|
        header = %w(日付 出社時間 退社時間)
        csv << header
        export_data.each do |exportData|
          values = [
            exportData.worked_on,
            if exportData.started_at
              round15Minites(exportData.started_at).strftime("%H:%M")
            else
              ""
            end,
            if exportData.finished_at
              round15Minites(exportData.finished_at).strftime("%H:%M")
            else
              ""
            end
          ]
          csv << values
        end
      end
      send_data(csv_data, filename: "export.csv")
    end

end