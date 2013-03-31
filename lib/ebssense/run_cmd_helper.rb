module Ebssense
  module RunCmdHelper
    def info(message)
      @log.info(message)
    end

    def debug(message)
      @log.debug(message)
    end

    def run_cmd(cmd, failok=false)
      #cmd = "/usr/bin/sudo #{cmd}"
      cmd = cmd.split(/ /)
      info "run_cmd: starting #{cmd}"
      output = ""
      IO.popen([*cmd, :err=>[:child, :out]]) do |io|
        output = io.read
      end
      info output
      if $?.success?
        info "Command success: #{cmd}"
        return true
      else
        info "Command failed: #{cmd}"
        raise "FATAL: command failed and failok was not specified." unless failok
      end
    end
  end
end
