class App < File
  F = ::File

  # Override #_call to mimic the rewrites done by nginx.
  def _call(env)
    path_info = Utils.unescape(env["PATH_INFO"])
    path = F.join(@root, path_info)

    unless F.file?(path)
      # Serve index.html on requests for directories with an index.
      if F.file?(F.join(path, 'index.html'))
        path_info.sub!(/\/?$/, '/index.html')
      end

      # Expand foo/bar to foo/bar.html when the .html version exists.
      if F.file?(path + '.html')
        path_info << '.html'
      end

      env["PATH_INFO"] = path_info
    end

    super
  end
end

run App.new('public')
