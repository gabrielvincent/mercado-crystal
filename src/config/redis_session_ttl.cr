require "kemal-session-redis-engine"

class Kemal::Session::RedisEngine
  private def refresh_ttl(session_id : String)
    @redis.expire(prefix_session(session_id), Kemal::Session.config.timeout.total_seconds.to_i)
  end

  def load_into_cache(session_id)
    @cached_session_id = session_id
    value = @redis.get(prefix_session(session_id))

    if value.nil?
      @cache = StorageInstance.new
    else
      @cache = StorageInstance.from_json(value)
      refresh_ttl(session_id)
    end

    @cache
  end
end
