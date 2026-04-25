require "../models/user"
require "../queries/user_query"

module UserRepository
  extend self

  def find_by_email(email : String) : User?
    UserQuery.new.email(email).first?
  end

  def find(id : Int64) : User?
    UserQuery.new.id(id).first?
  end
end
