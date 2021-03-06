require 'net/http'
require 'json'

class Api::V1::UsersController < ApplicationController

    def index
        @users = User.all
        render json: @users, include: ['logs', 'timed_logs']
    end

    def show
        @user = User.find_by_id(params[:id])
        render json: @user
        # {user: @user, img_url: url_for(@user.image) }
    end

    def login
      @user = User.find_by(email: params[:email])
      if @user && @user.authenticate(params[:password])
        render :json => { :token => JWT.encode({ user_id: @user.id }, ENV['JWT_SECRET'], 'HS256') }
      else
        render :json => { :message => "Your username or password is incorrect..." }, status: 403
      end
    end

    def profile
        me = try_get_user
        if me == nil
          render :json => {
            :message => "You cannot view this profile."
          }, status: 403
        end

        render json: me
    end

    def create
        @user = User.create(user_params)
        if @user.valid?
            @token = JWT.encode({ user_id: @user.id }, ENV['JWT_SECRET'], 'HS256')
            render json: { user: UserSerializer.new(@user), token: @token }, status: :created
        else
            render json: { error: @user.errors }, status: :not_acceptable
        end
    end

    def update
        user = User.find_by_id(params[:id])
        if user == nil
            render json: {message: 'Could not update user.'}
        else
            @log = user.update(user_params)
            render json: @user, status: :created
        end
    end

    def horoscope
        url = URI.parse('http://horoscope-api.herokuapp.com/horoscope/today/' + params[:sign])
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        render json: JSON.parse(res.body)
    end

    private

    def user_params
        params.require(:user).permit(:name, :email, :password, :birthday, :avatar)
    end
end
