require 'openssl'
require 'base64'

class ApiController < ApplicationController
	# skip_before_action :vertify_authenticity_token
	protect_from_forgery with: :null_session

	def token
		username = token_params[:username]
		password = token_params[:password]

		if username.to_s.strip.empty? or password.to_s.strip.empty?
			render json: {token: nil, message: "Please refer to the API documentation (if any).", success: false}
			return
		end

		username = Base64.urlsafe_decode64 username
		password = Base64.urlsafe_decode64 password

		user = User.find_by(username: username)
		if user.nil? or !user.authenticate password
			render json: {token: nil, message: "Invalid username or password.", success: false}
			return
		end
        
        # Keep generating tokens until no user with that token exists.
        if user.regenerate_auth_token
			render json: {token: user.auth_token, message: "Welcome, #{user.get_name}!", success: true}
		else
			render json: {message: "Sorry, our server authenticated you but could not log you in.", success: false}
		end
	end

    def check
        token = token_params[:token]
        if token.to_s.strip.empty?
            render json: {message: "Missing token", success: false}
            return
        end
        user = User.find_by(auth_token: token)
        if user
            json = {success: true, message: "Welcome back, #{user.get_name}!"}
        else
            json = {success: false, message: "It appears you have been logged out. Please re-enter your credentials."}
        end
        render json: json
    end

	private
		def token_params
			params.permit(
				:username,
				:password,
                :token
			)
		end

end