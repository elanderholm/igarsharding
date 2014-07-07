class ApplicationController < ActionController::Base
  class AuthenticationError < StandardError; end

  protect_from_forgery

  around_filter :select_shard

  rescue_from ActiveRecord::RecordNotFound do
    render nothing: true, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    render nothing: true, status: :unprocessable_entity
  end

  rescue_from AuthenticationError do
    respond_to do |format|
      format.html { redirect_to new_session_path }
      format.all { render nothing: true, status: :unauthorized }
    end
  end

  def logged_in?
    current_user.present?
  end

  helper_method :logged_in?

  def current_user
    unless defined?(@current_user)
      @current_user = if session['X-Authentication-Token']
                        token = AuthenticationToken.parse(session['X-Authentication-Token'])
                        Sharting.using_key(token.user_email){ token.user }
                      elsif session[:user_email]
                        Sharting.using_key(session[:user_email]) { User.find_by_email(session[:user_email]) }
                      end
    end
    @current_user
  end

  helper_method

  def current_user=(user)
    @current_user = user
  end

  def require_authentication
    raise AuthenticationError unless logged_in?
  end

  def reject_authentication
    redirect_to root_path if logged_in?
  end

  def select_shard
    select_current_user_shard { yield }
  end

  def select_current_user_shard
    if logged_in?
      Sharting.using_key(current_user.email) { yield }
    else
      yield
    end
  end
end
