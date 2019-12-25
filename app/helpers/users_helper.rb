module UsersHelper
  # 基本時間などの値を、指定の書式にフォーマットして返す
  def format_basic_time(datetime)
    format("%.2f", ((datetime.hour * 60) + datetime.min)/60.0)
  end

  # user_idを指定してUserを取得するメソッド
  def getUser(user_id)
    return User.find(user_id)
  end

end