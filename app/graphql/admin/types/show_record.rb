# frozen_string_literal: true
module Admin
  module Types
    class ShowRecord < ::Types::BaseObject
      connection_type_class ::Types::Custom::BaseConnection

      field :title, String, null: false
      field :description, String, null: false
      field :slug, String, null: false
      field :id, ID, null: false
      field :show_type, String, null: false
      field :show_category, String, null: true
      field :popularity, Integer, null: false
      field :popularity_percentage, Integer, null: false
      field :relative_popularity, Integer, null: false
      field :youtube_trailer_url, String, null: true
      field :banner_url, String, null: false
      field :poster_url, String, null: true
      field :current_poster_url, String, null: true
      field :published, GraphQL::Types::Boolean, null: false
      field :poster, Queries::Types::Shows::Poster, null: false
      field :likes, Integer, null: false
      field :dislikes, Integer, null: false
      field :loves, Integer, null: false
      field :rank, Integer, null: true
      field :episodes_count, Integer, null: false
      field :nsfw, GraphQL::Types::Boolean, null: false
      field :age_rating, Queries::Types::Shows::AgeRating, null: false
      field :year, Integer, null: true
      field :starts_on, Integer, null: true
      field :ended_on, Integer, null: true
      field :airing_at, Integer, null: true
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
      field :next_episode, Integer, null: true
      field :status, Queries::Types::Shows::AiringStatus, null: true
      field :friendly_status, String, null: true
      field :platforms, [Queries::Types::Shows::Platform], null: false do
        argument :focus_on, String, required: false
        argument :region_locked, Queries::Types::Shows::Platforms::RegionLocked, required: false
      end
      field :links, [Queries::Types::Shows::Link], null: false do
        argument :region_locked, Queries::Types::Shows::Platforms::RegionLocked, required: false
      end
      field :other_links, [Queries::Types::Shows::Link], null: false
      field :tags, [Queries::Types::Shows::Tag], null: false
      field :related_shows, [Admin::Types::ShowRecord], null: false
      field :title_record, Queries::Types::Shows::Title, null: false
      field :titles, ::Types::Custom::Map, null: false
      field :added_by_users_count, Integer, null: false

      def current_poster_url
        @object.poster.url
      end

      def starts_on
        @object.starts_on&.to_time&.to_i
      end

      def ended_on
        @object.ended_on&.to_time&.to_i
      end

      def airing_at
        @object.airing_at&.to_time&.to_i
      end

      def likes
        @object.likes_count
      end

      def dislikes
        @object.dislikes_count
      end

      def loves
        @object.loves_count
      end

      def age_rating
        {
          rating: @object.age_rating || 'N/R',
          guide: @object.age_rating_guide,
        }
      end

      def title_record
        {
          en: I18n.with_locale(:en) { @object.title },
          jp: I18n.with_locale(:ja) { @object.title },
        }
      end

      def description
        @object.description || '- No description -'
      end

      def show_type
        return @object.show_type if @object.show_category.blank?

        "#{@object.show_category}/#{@object.show_type}"
      end

      def friendly_status
        return unless @object.status.present?

        I18n.t("anime.shows.airing_status.#{@object.status}")
      end

      def links(region_locked: nil)
        links = @object.links
        return links if region_locked.blank?

        links.select do |link|
          link.platform.available?(region_locked[:for_country])
        end
      end

      def platforms(focus_on: nil, region_locked: true)
        @object.platforms(focus_on: focus_on, for_country: (region_locked ? context[:country] : nil))
      end

      def poster_url(dimensions: nil)
        return @object.poster_url unless dimensions.present?

        @object.poster.variant(resize: dimensions).processed.url
      end

      def poster
        @object.poster_record
      end

      def added_by_users_count
        @object.queues.count
      end
    end
  end
end