require "kemal"

static_headers do |env, filepath, _filestat|
  basename = File.basename(filepath)
  headers = env.response.headers

  headers["Vary"] = "Accept-Encoding"

  case basename
  when "tailwind.css", "home.js"
    # App-owned assets are not fingerprinted yet, so keep this cache short.
    headers["Cache-Control"] = "public, max-age=3600"
  else
    headers["Cache-Control"] = "public, max-age=31536000, immutable"
  end
end
