class TrackableJob < ApplicationJob
  # Call perform_[now/later](model?, staff: Staff)

  around_perform do |job, block|
    event = before_perform(job)
    begin
      block.call if block

      after_perform(event)
    rescue => e
      event.mark_as_failed!(e)
      puts e
      puts e.backtrace
      raise e
    end
  end

  private

  def before_perform(job)
    model = model_from_args!(job)

    JobEvent.create!(
      job_id: job.job_id,
      staff: staff_from_args(job) || Staff.system,
      model_id: model&.id,
      used_by_model: model&.class&.table_name,
      job_name: self.class.name,
      started_at: Time.now.utc,
    )
  end

  def after_perform(event)
    event.mark_as_complete!
  end

  def staff_from_args(job)
    fetch_arg_from_args(job, Staff, :staff)
  end

  def model_from_args!(job)
    model = job.arguments.first
    return unless model.kind_of?(ApplicationRecord)

    model
  end

  def fetch_arg_from_args(job, klass, type)
    job.arguments.each do |arg|
      return arg if arg.kind_of?(klass)

      if arg.kind_of?(Hash)
        return arg[type] if arg.keys.include?(type)
      end
    end

    nil
  end
end