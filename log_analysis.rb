require 'time'

# Verify a file is passed as a parameter - otherwise return usage
if ARGV.empty?
  puts 'No parameters were provided.  Usage:'
  puts 'log_analysis.rb <log_file>'
  exit
end

class LogAnalysis

  def analyze_log
    # Read the log file provided by the first argument, then
    # analyze the actions in to processing times per server

    # Begin reading file, return error if the file is invalid
    begin
      last_time = {}

      # Open file (read) specified by first script argument parameter
      file = File.new(ARGV[0], 'r')

      # Parse through each line until EOF
      while (line = file.gets)
        # Split the line based on space chars, assign variables
        line_vals = line.split(' ')
        curr_time = line_vals[0]
        curr_guid = line_vals[1]
        curr_action = line_vals[2]
        curr_server = line_vals[7]
        curr_timeval = Time.iso8601(line_vals[0])

        # Branch based on HTTP action specified
        case curr_action
          when 'GET', 'POST'
            # This should be the first GUID entry, just record the time
            last_time[curr_guid] = curr_time
          when 'HANDLE', 'RESPOND'
            # Calculate the run time for this action

            # Initialize the response time hash for this server if no values exist
            if !@response_time.has_key?(curr_server)
              @response_time[curr_server] = []
            end

            # Verify there actually is a previous time for this GUID, if not, skip
            if last_time.has_key?(curr_guid)
              last_timeval = Time.iso8601(last_time[curr_guid])
              @response_time[curr_server].push (curr_timeval - last_timeval)
            end

            # Record this line's time as the last process for this GUID
            last_time[curr_guid] = curr_time
          else
            # Return the unknown action for troubleshooting
            p "Unknown action: #{curr_action}"
        end
      end
    rescue => err
      # Handle any file related errors
      puts "Error encountered: #{err}"
      err
    end
  end

  def initialize
    @response_time = {}
    self.analyze_log
  end

  def output_times
    # Dump the average and longest times for each server to stdout

    # Run through each server
    @response_time.each do |key, value|
      curr_total = 0
      curr_longest = 0

      # Run through each recorded process time for this server
      value.each do |timeval|
        curr_total += timeval
        timeval > curr_longest ? curr_longest = timeval : true
      end

      # Calculate the average - if there were no values, return 0
      value.length > 0 ? curr_avg = curr_total / value.length : curr_avg = 0

      # Output the values for this server
      p "Server: #{key}, average response: #{curr_avg}, longest time: #{curr_longest}"
    end
  end
end

# Initialize the log analysis object, then output the results
logger = LogAnalysis.new
logger.output_times

