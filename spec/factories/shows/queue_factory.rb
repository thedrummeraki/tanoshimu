# frozen_string_literal: true

FactoryBot.define do
  factory :shows_queue, class: 'Shows::Queue' do
    user
  end
end
