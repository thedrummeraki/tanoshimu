module Shows
  module Update
    class ManyShows < ApplicationOperation
      property! :show_ids, accepts: Array, converts: :to_a

      def perform
        Show.where(id: show_ids).each do |show|
          ::Shows::Kitsu::Get.perform(
            kitsu_id: show.id,
            force_update: true,
          ) if show.kitsu?
        end
      end
    end
  end
end
