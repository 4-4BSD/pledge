def main(argv)
  command = []
  pledges = ["exec", "proc"]
  while o = argv.shift
    case o
    when "-p" then pledges.push(argv.shift)
    else command.push(o)
    end
  end
  pledge(pledges.join(" "))
  execvp(*command)
end
main(ARGV)