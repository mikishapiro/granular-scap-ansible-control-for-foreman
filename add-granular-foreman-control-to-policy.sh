#!/bin/bash
[ "x$1" = x ] && echo "Usage: $0 policy.yml policy-foreman-tag" && exit 0
case `uname` in
   "Linux")	quiet_switch='-e';;
   "Darwin")	quiet_switch='-n';;
esac
sed $quiet_switch '{
  /^.*CEE-.*.log/{
    H
    d
  }
  /^.*CEE-.*.sh/{
    H
    d
  }
  /[ ]*#.*/{
    H
    d
  }
  /^      tags.*/{ 
    s@^      tags.*@      when:\
        - '\''"'$2'" in policies'\''\
&@
    x
    p
    d
  }
  /^.*CCE.*/{
    H
    g
    s@      tags.*CCE-\(.*\)$@        - '\''"CCE-\1" not in policy_exemptions'\''\
&@
    x
    d
   }

  H
  $x
  $p
  d
}
' $1
