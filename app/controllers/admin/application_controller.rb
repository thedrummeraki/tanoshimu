module Admin
  class ApplicationController < ::ApplicationController
    layout 'admin'
    
    before_action :ensure_title

    def home
      @users_count = User.where.not(user_type: [User::GOOGLE, User::MISETE]).count
      @oauth_users_count = User.where(user_type: [User::GOOGLE, User::MISETE]).count
      @shows_count = Show.published.count
      @currently_watching_count = 0
      @currently_logged_in_count = currently_logged_in.count
      @top_episodes = Episode.includes(season: :show).limit(10)
      @top_shows = Show.includes(:title_record, :ratings).limit(10)
    end

    private

    def currently_logged_in
      Users::Session.all.select do |session|
        session.active?
      end.map do |session|
        session.user
      end.uniq
    end

    def ensure_title
      set_title(after: 'Admin panel')
    end
  end
end