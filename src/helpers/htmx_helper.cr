module HtmxHelper
  extend self

  def retarget(env, selector : String, swap : String = "innerHTML")
    env.response.headers["HX-Retarget"] = selector
    env.response.headers["HX-Reswap"] = swap
  end

  def request?(env) : Bool
    env.request.headers["HX-Request"]? == "true"
  end
end
