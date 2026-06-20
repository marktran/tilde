#!/usr/bin/env ruby
# frozen_string_literal: true

module ChromecastCommon
  module_function

  DEFAULT_CONF = File.join(ENV.fetch("HOME", ""), ".config/mpv/script-opts/chromecast-cast.conf")

  def config_path
    ENV["MPV_CHROMECAST_CONF"] || DEFAULT_CONF
  end

  def load_options(path = config_path)
    opts = {}
    return opts unless File.file?(path)

    File.foreach(path) do |raw_line|
      line = raw_line.strip
      next if line.empty? || line.start_with?("#")
      next unless line.include?("=")

      key, value = line.split("=", 2)
      opts[key.strip] = value.to_s.strip
    end

    opts
  end

  def truthy?(value, default: false)
    val = value.to_s.strip
    return default if val.empty?

    case val.downcase
    when "1", "true", "yes", "on"
      true
    else
      false
    end
  end

  def floor_nonneg(value, default: 0)
    num = Float(value)
    floored = num.floor
    floored.negative? ? 0 : floored
  rescue StandardError
    default
  end

  def resolve_catt_bin(opts)
    bin = opts.fetch("catt_bin", "/usr/bin/catt").to_s.strip
    bin.empty? ? "/usr/bin/catt" : bin
  end

  def with_device(args, opts)
    device = opts.fetch("device", "").to_s.strip
    return args if device.empty?

    args + ["-d", device]
  end
end
