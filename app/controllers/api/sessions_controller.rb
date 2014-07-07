module Api
  class SessionsController < Api::Base
    def create
      self.current_user = User.authenticate(params[:user_email], params[:password])
      require_authentication

      respond_to do |format|
        format.json { render json: session_json, status: :created }
      end
    end

    def destroy
      self.current_user = nil
      session[:user_email] = nil

      respond_to do |format|
        format.json { render nothing: true, status: :no_content }
      end
    end

    private

    def session_json
      token = AuthenticationToken.build(current_user)
      { session: {token: token.to_s, user: token.token_hash} }
    end
  end
end