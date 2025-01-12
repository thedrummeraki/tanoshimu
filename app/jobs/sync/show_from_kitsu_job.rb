# frozen_string_literal: true
module Sync
  class ShowFromKitsuJob < TrackableJob
    queue_as :sync

    def perform(show)
      ::Shows::Sync.perform(sync_type: :show, show: show, requested_by: Users::Admin.system)
    end
  end
end
