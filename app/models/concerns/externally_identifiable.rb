module ExternallyIdentifiable
  extend ActiveSupport::Concern

  included do
    scope :with_external_id, ->(provider, external_id) {
      joins(:external_ids).where(external_ids: { provider: provider, external_id: external_id })
    }
  end

  class_methods do
    def find_by_external_id(provider:, external_id:)
      with_external_id(provider, external_id).first
    end
  end
end
