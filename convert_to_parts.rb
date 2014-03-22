require 'rubygems'
require 'bundler/setup'

require 'midilib'
include MIDI

# Create a new, empty sequence.
seq = MIDI::Sequence.new()

# Read the contents of a MIDI file into the sequence.
File.open(ARGV[0], 'rb') do |file|
  seq.read(file) do |track, num_tracks, i|
    # Print something when each track is read.
    puts "read track #{i} of #{num_tracks}"
  end
end

parts = seq.tracks.map(&:name).reject {|name| name == "Unnamed" } << "All"

parts.each do |part|
  out = seq
  out.tracks.each do |track|
    this_part = true if track.name == part || part == "All"
    event_with_channel = track.events.detect {|e| e.respond_to?(:channel) }
    channel = event_with_channel ? event_with_channel.channel : nil
    track.events.map! do |event|
      case event
      when MIDI::ProgramChange
        #event.program = this_part ? 25 : 0 #52
        event.program = this_part ? 0 : 52
      when MIDI::Controller
        next unless event.controller == MIDI::CC_VOLUME
        event.value = this_part ? 127 : 100
      end
      event
    end

    #if channel
      #pan = this_part ? 0 : 127
      #track.events.unshift MIDI::Controller.new(channel, MIDI::CC_PAN, pan)
    #end
    track.events.compact!
  end

  base = File.basename(ARGV[0], '.mid')
  filename = (base + "-#{part}").gsub(/ /, '-')
  dir = "out/#{base.gsub(/ /, '-')}/"
  FileUtils.mkdir_p(dir)
  midi_filename = dir + filename + '.mid'
  File.open(midi_filename, 'wb') { | file | out.write(file) }
  %w(guitar piano).each do |lead|
    mp3_filename = dir + filename + "-#{lead}.mp3"
    `timidity #{midi_filename} -c #{lead}.cfg -F -Ow -o - | lame - -b 64 #{mp3_filename}`
  end
end


