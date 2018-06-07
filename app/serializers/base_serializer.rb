class BaseSerializer < ActiveModel::Serializer
  def initialize(object, options = {})
    super
    @scopes = options[:scopes]
  end

  def scopes?(attr)
    @scopes && @scopes.include?(attr)
  end
end
