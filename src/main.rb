def main(argv)
  command = []
  pledges = ["exec", "proc"]
  has_pledges = false
  while o = argv.shift
    case o
    when "-p"
      pledges.push(argv.shift)
      has_pledges = true
    else
      if has_pledges
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