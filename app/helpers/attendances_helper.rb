module AttendancesHelper

  def current_time
    Time.new(
      Time.now.year,
      Time.now.month,
      Time.now.day,
      Time.now.hour,
      Time.now.min, 0
    )
  end

  def working_times(started_at, finished_at)
    format("%.2f", (((finished_at - started_at) / 60) / 60.0))
  end

  def working_times_sum(seconds)
    format("%.2f", seconds / 60 / 60.0)
  end

  def first_day(date)
    !date.nil? ? Date.parse(date) : Date.current.beginning_of_month
  end

  def user_attendances_month_date
    @user.attendances.where('worked_on >= ? and worked_on <= ?', @first_day, @last_day).order('worked_on')
  end

  def attendances_invalid?
    attendances = true
    attendances_params.each do |id, item|
      if item[:started_at].blank? && item[:finished_at].blank?
        next
      elsif item[:started_at].blank? || item[:finished_at].blank?
        attendances = false
        break
      elsif item[:started_at] > item[:finished_at]
        attendances = false
        break
      end
    end
    return attendances
  end

  def weekDayColor(wday)
    if wday == 0
      return 'sunday'
    elsif wday == 6
      return 'saturday'
    end
  end

  def round15Minites(datetime)
    minutes = 0
    if datetime.min >= 15 and datetime.min <= 29
      minutes = 15
    elsif datetime.min >= 30 and datetime.min <= 44
      minutes = 30
    elsif datetime.min >= 45 and datetime.min <= 59
      minutes = 45
    end
    return Time.new(datetime.year, datetime.month, datetime.day, datetime.hour, minutes, datetime.sec)
  end

  def getStatusList()
    return ["なし","申請中","承認","否認"]
  end

  def getStatus(status)
    return getStatusList()[status]
  end

end