def main(argv)
  command = []
  pledges = ["exec", "proc"]
  has_pledges = false
  has_command = false
  while o = argv.shift
    case o
    when "-p"
      if has_command
        command.push(o)
      else
        pledges.push(argv.shift)
        has_pledges = true
      end
    else
      if has_pledges
        has_command = true
        command.push(o)
      else
        warn "pledge: -p switch must appear before command"
        exit(1)
      end
    end
  end
  pledge(pledges.join(" "))
  execvp(*command)
end
main(ARGV)