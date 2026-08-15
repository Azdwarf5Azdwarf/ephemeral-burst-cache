# frozen_string_literal: true

require "date"
require "fileutils"
require "tmpdir"

module EBC
  # The camera.
  #
  # At the end of a real hangout you ask someone to take a picture of you and
  # your friends. Hand that picture to this and the three poets get drawn into
  # it — they were there too, so they belong in the shot. They're rendered on
  # a flat chroma background, keyed out, and composited over your photo, the
  # way a cartoon gets pasted into a real scene.
  #
  # Only the drawn ones move between frames. Your friends hold still, because
  # they were actually there. That's the animation, and it's honest about who
  # was real.
  #
  # With no photo, it falls back to drawing the whole scene — you still get a
  # picture, it's just nobody's face in it.
  class GroupPhoto
    class Error < StandardError; end

    POSES = [
      "settling into the frame, just arriving",
      "half a second later, one of them shifting their weight",
      "one of them glancing sideways at another",
      "the moment just before everyone breaks apart"
    ].freeze

    # Flat magenta keys out cleanly and almost never shows up in a character.
    CHROMA = "magenta"
    KEY_FUZZ = "25%"
    POET_SCALE = 0.55 # of the photo's height

    GIF_TOOLS = %w[magick convert].freeze

    def initialize(burst, client: GrokClient.new)
      @burst = burst
      @client = client
    end

    # `photo` is the real picture you took. Omit it and the whole thing gets
    # drawn instead. Returns the path of the one artifact that survives.
    def run(verdict, photo: nil, frames: Config::FRAME_COUNT, out_dir: Config::PHOTO_DIR)
      raise Error, "no verdict — nothing to photograph" if verdict.nil?
      raise Error, "no such photo: #{photo}" if photo && !File.exist?(photo)

      tool = gif_tool
      FileUtils.mkdir_p(out_dir)
      out = photo_path(out_dir, verdict.mood, @burst.laughter)

      Dir.mktmpdir("ebc-frames") do |tmp|
        paths = (0...frames).map do |index|
          render(tool, tmp, index, verdict, photo)
        end
        assemble(tool, paths, out)
      end

      out
    end

    private

    def render(tool, tmp, index, verdict, photo)
      pose = POSES[index % POSES.length]
      frame = File.join(tmp, format("frame-%02d.png", index))

      if photo
        poets = File.join(tmp, format("poets-%02d.png", index))
        File.binwrite(poets, @client.image_bytes(poets_prompt(verdict, pose)))
        composite(tool, photo, poets, frame)
      else
        File.binwrite(frame, @client.image_bytes(whole_scene_prompt(verdict, pose)))
      end

      frame
    end

    # The poets alone, on flat chroma, ready to be cut out.
    def poets_prompt(verdict, pose)
      <<~PROMPT.gsub(/\s+/, " ").strip
        Three cartoon characters standing together, full body, facing forward:
        Frost, who is pale and stark and wintry;
        Cicada, who is wiry and restless and looks like they are talking too fast;
        Ember, who is warm and rumpled and quietly amused.
        Clean illustrated style with bold outlines, like a sticker or a decal.
        They look #{verdict.mood}#{laughter_clause}.
        Right now: #{pose}.
        They stand on a completely flat solid #{CHROMA} background —
        no floor, no shadow, no scenery, no gradient, nothing behind them.
        No text, no words, no captions anywhere in the image.
      PROMPT
    end

    # Fallback when nobody took a picture.
    def whole_scene_prompt(verdict, pose)
      cast = @burst.participants
      who = cast.empty? ? "a small group" : cast.join(", ")

      <<~PROMPT.gsub(/\s+/, " ").strip
        A warm illustrated group photo of #{who}, together with three characters
        named Frost, Cicada and Ember. #{verdict.scene}
        The mood is #{verdict.mood}#{laughter_clause}.
        Right now: #{pose}.
        Painterly and charming, everyone in one shot, facing the camera.
        No text, no words, no captions anywhere in the image.
      PROMPT
    end

    def laughter_clause
      count = @burst.laughter
      return "" if count.zero?
      return ", and one of them just laughed" if count == 1
      return ", and they have been laughing a lot" if count >= 4

      ", and they have been laughing"
    end

    # Key the chroma out and paste the poets over the real photo.
    def composite(tool, photo, poets, out)
      height = (image_height(tool, photo) * POET_SCALE).round
      ok = system(
        tool, photo,
        "(", poets, "-fuzz", KEY_FUZZ, "-transparent", CHROMA, "-resize", "x#{height}", ")",
        "-gravity", "south", "-composite", out
      )
      raise Error, "#{tool} could not draw the poets into your photo" unless ok && File.exist?(out)

      out
    end

    def image_height(tool, path)
      identify = tool == "magick" ? %w[magick identify] : %w[identify]
      value = IO.popen([*identify, "-format", "%h", path], &:read).to_s.strip
      raise Error, "could not read the size of #{path}" if value.empty?

      Integer(value)
    rescue Errno::ENOENT, ArgumentError
      raise Error, "could not read the size of #{path}"
    end

    # photos/2026-08-15-delighted-4laughs.gif — never silently overwriting a
    # picture that already exists.
    def photo_path(dir, mood, laughs)
      base = "#{Date.today.iso8601}-#{mood}-#{laughs}laughs"
      path = File.join(dir, "#{base}.gif")
      return path unless File.exist?(path)

      File.join(dir, "#{base}-#{@burst.uuid[0, 4]}.gif")
    end

    def gif_tool
      GIF_TOOLS.find { |tool| system("command -v #{tool} > /dev/null 2>&1") } ||
        raise(Error, "no GIF tool found — install ImageMagick (#{GIF_TOOLS.join(" or ")})")
    end

    def assemble(tool, frame_paths, out_path)
      ok = system(tool, "-delay", "60", "-loop", "0", *frame_paths, out_path)
      raise Error, "#{tool} failed to assemble the photo" unless ok && File.exist?(out_path)

      out_path
    end
  end
end
