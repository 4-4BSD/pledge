##
# main

def main(argv)
  ##
  # The following pledges are required to bootstrap
  # a process. The new process inherits these abilities,
  # plus whatever other pledges are provided at the command
  # line.
  pledges = ["exec", "proc"]
  execpledges = []
  command = []
  if argv.empty?
    return help
  end
  parse_options(argv, execpledges, command)
  pledge([*pledges, *execpledges].join(" "), execpledges.join(" "))
  execvp(*command)
end

##
# Utils

def help
  warn <<~'HELP'
  pledge [OPTIONS] program arguments

  Options:
    -p    The name of a pledge.
    -h    Show help.

  Examples:
    pledge -p ioctl ls /
    pledge -p inet -p ioctl curl https://freebsd.org
  HELP
end

def parse_options(argv, pledges, command)
  has_command = false
  has_pledges = false
  while option = argv.shift
    case option
    when "-h"
      if has_command
        command.push(option)
      elsif has_pledges
        warn "pledge: -h and -p can't be combined\n"
        exit(1)
      else
        help
        exit(0)
      end
    when "-p"
      if has_command
        command.push(option)
      else
        pledges.push(argv.shift)
        has_pledges = true
      end
    else
      if has_pledges
        has_command = true
        command.push(option)
      else
        warn "pledge: -p switch must appear before command\n"
        exit(1)
      end
    end
  end
end

##
# Let's go

main(ARGV)