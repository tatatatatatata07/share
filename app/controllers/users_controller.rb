class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy
  before_action :mix_name,       only: [:create, :update]
  
  def index
    #検索のパラメータ「search」に値が入っていれば検索結果を返し、そうでなければユーザー一覧を表示する
    if params[:search] == nil
      @users = User.where(activated: true).paginate(page: params[:page], per_page: 30)
      @count = false
    elsif params[:search] == ""
      @users = User.where(activated: true).paginate(page: params[:page], per_page: 30)
      @blank = true
    else
      @users = User.where(activated: true).where("name LIKE ?", "%#{params[:search]}%").paginate(page: params[:page], per_page: 30)
      @count = @users.count
    end
    
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    @user.name = @name
    #お試しログイン用のユーザーを作らせない
    if @user.email != "gest@example.com" && @user.save
      @user.send_activation_email
      flash[:info] = "ご登録いただいたメールアドレスに送信しました。メールをご確認いただき、ご登録をお願い致します。"
      redirect_to login_path
    else
      render 'new'
    end
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    @user.name = @name
    if @user.update_attributes(user_params) && @user.update_attributes(name: @user.name)
      flash[:success] = "変更が完了しました"
      redirect_to @user
    else
      render 'edit'
    end
  end
  
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "削除が完了しました"
    redirect_to users_url
  end
  
  def trial_user_destroy
    if current_user.email == "gest@example.com"
      User.find_by(email: "gest@example.com").destroy
      flash[:success] = "お試しログインをご使用いただきありがとうございました ログアウト及びデータ削除が完了しました"
      if params[:create] == "1"
        redirect_to new_user_path
      else
        redirect_to root_path
      end
    else
    end
    
  end
  
  def feed
    Meeting.where("user_id = ?", id)
  end
  
  def following
    @title = "フォローしているユーザー一覧"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "フォローされているユーザー一覧"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end
  
  #facebook認証の処理
  def facebook_login
    @user = User.from_omniauth(request.env["omniauth.auth"])
    result = @user.save(context: :facebook_login)
    if result
      @user.activate
      log_in @user
      redirect_to @user
    else
      redirect_to auth_failure_path
    end
  end
  
  #facebook認証認証に失敗した際の処理
  def auth_failure 
    @user = User.new
    render 'new'
  end
  
  #お試しログイン
  def trial_login
    #前のユーザーがログアウトを忘れていたときの対応
    #ログアウトを忘れたときに再度ログインできなくなることを防止
    if user = User.find_by(email: "gest@example.com")
      user.destroy
    end
    @user = User.new
    @user.email = "gest@example.com"
    @user.name = "ゲスト"
    result = @user.save(context: :trial_login)
    if result
      @user.activate
      log_in @user
      redirect_to users_path
    else
      redirect_to root_path
    end
  end
    
  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end
    
    #「お試しユーザーではなく」かつ「正しいユーザー」を確認する
    #お試しユーザーをedit及updateさせないために、例え「正しいユーザー」であっても除外する
    def correct_user
      @user = User.find(params[:id])
      if current_user?(@user)
        if trial_user?
          redirect_to(root_url)
        end
      else
        redirect_to(root_url)
      end
    end
    
    #現在のユーザーが管理者権限を持っていなければ処理をさせずルートURLへ移動
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
    
    #姓名分けて入力していただいたデータを半角スペースを入れて統合する
    def mix_name
      @name = params[:user][:first_name] + " " + params[:user][:last_name]
    end
    
end
