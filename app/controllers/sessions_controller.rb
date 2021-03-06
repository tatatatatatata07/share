class SessionsController < ApplicationController
  def new
  end
  
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    #簡単ログイン対応
    if user && user.email == "gest@example.com"
      log_in user
      redirect_to users_path and return
    end
    #通常ログイン対応
    if user && user.authenticate(params[:session][:password])
      if user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      else
        message  = "アカウントがアクティベーションされていません。 "
        message += "メールに送信されたURLをご確認ください"
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'パスワードかメールアドレスのどちらかに誤りがあります'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
  
end
