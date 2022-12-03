class NotifySubscribedUsersJob < TrackableJob
  queue_as :batch_queue

  def perform(action, target_ids, model_class, model_id)
    model = model_class.safe_constantize&.find(model_id)
    if model.nil?
      raise ArgumentError.new("Invalid model. Could not find a model with #{model_class}.find(#{model_id})")
    end

    target_ids.each do |target_id|
      try_to_notify(target_id, action, model)
    end
  end

  private

  def try_to_notify(target_id, action, model)
    subscription_target = SubscriptionTarget.find(target_id)
    subscription_target.notify!(action, model)
  rescue Exception => error
    Rails.logger.error("[#{self.class.name}] Could not notify target #{target_id} (action: #{action}) with model #{model}")
    Rails.logger.error("[#{self.class.name}] Details: #{error}")
  end
end