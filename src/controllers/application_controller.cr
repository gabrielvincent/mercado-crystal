require "../models/user"

module ApplicationController
  extend self

  def current_user(env) : User
    env.get("current_user").as(User)
  end
end
