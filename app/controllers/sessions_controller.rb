class SessionsController < ApplicationController

  def new
  end
  
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
       # ユーザーログイン後にユーザー情報のページにリダイレクトする
       log_in(user)
      # log_in user
      # redirect_to user
      redirect_back_or user
    else
      # エラーメッセージ用のflashを入れる
      flash.now[:danger] = 'メールアドレスとパスワードの情報が一致しませんでした。'
      render 'new'
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end

end
