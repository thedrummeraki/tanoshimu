# frozen_string_literal: true
module Admin
  class QueryType < ::Types::BaseObject
    field :ping, type: String, null: false
    def ping
      'pong'
    end

    field :home_feed, Admin::Types::HomeFeed, null: false
    def home_feed
      {
        users: GraphqlUser.count,
        admin_users: Admin::User.count,
        jobs_running: JobEvent.running.count,
        shows: Show.count,
        issues: Issue.count,
      }
    end

    field :shows, type: Types::ShowRecord.connection_type, null: false do 
      argument :query, type: String, required: false
    end
    def shows(query: nil)
      if query.present?
        Search.perform(search: query, limit: 20, format: :shows)
      else
        Show.all.with_attached_poster
      end
    end

    field :show, type: Types::ShowRecord, null: true do
      argument :slug, type: String, required: true
    end
    def show(slug:)
      Show.find_by(slug: slug)
    end
  end
end
