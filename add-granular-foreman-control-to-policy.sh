#!/bin/bash
# This is a script written to allow two foreman parameters set for all hosts in a server fleet via hostgroup or overridden host parameters to exempt systems from specific scap controls 
# with a CCE tag, without fragmenting the job template in Ansible Tower into multiple differently parameterized templates.
# A single template running all SCAP controls can run on the entire fleet.  

# This script and its sed programs inject a "when" yml section into each play. 
# The section is a multi-line hash of conditions governing each play.
# The first hash member sets a requirement that foreman_params.policies include the policy name. 
# In sections where a tag named CCE-<number> is mentioned, a second when hash member is inserted requiring that this CCE number IS NOT in foreman_params.policy_exemptions hash

[ "x$1" = x ] && echo "Usage: $0 policy.yml policy-foreman-tag" && exit 0
case `uname` in
   "Linux")	quiet_switch='-e';;
   "Darwin")	quiet_switch='-n';;
esac
sed $quiet_switch '{

  # The next section will apply to lines mentioning CEE-xxxxx.log files
  /^.*CEE-.*.log/{ 
    # Append to the holding space as they are irrelevant
    H
    # ... and clear the pattern space.
    d
  }
  
  # The next section will apply to lines mentioning CEE-xxxxx.sh files
  /^.*CEE-.*.sh/{
    # Append to the holding space as they are irrelevant
    H
    # Clear the pattern space.
    d
  }

  # The next section will apply to lines with comments
  /[ ]*#.*/{
    # Append to the holding space as they are irrelevant
    H
    # Clear the pattern space.
    d
  }

  # the next section will apply for lines starting with six spaces and the word tags
  /^      tags.*/{ 
    # Substitute tags: with when: followed by a line expecting the policy tag to be mentioned in foreman_params.policies
    s@^      tags.*@      when:\
        - '\''"'$2'" in foreman_params.policies'\''\
&@
    # This above section is not complete yet. Swap the pattern space holding our modified section with the hold space containing everything we have accumulated and not yet printed
    x
    # Everything accumulated is now in the pattern space and the new modified section is in the hold space
    # Print out the pattern buffer
    p
    # Delete the pattern buffer and start on the next line of input
    d
  }
  # the next section will apply only for lines containing CEE. These are expected to be members of the tags hash
  /^.*CCE.*/{
    # Append the line to the holding space
    H
    # Copy the entire holding space into the pattern space
    g
    # Substitute the line starting the tags section with two lines
    # first complementing the previous "when" section with one more yaml hash member requiring the specific CCE number pulled from the tag not be in the exclusions foreman parameter
    # second - note the ampersand after the new line - reinserts the tags line after the when clause
    s@      tags.*CCE-\(.*\)$@        - '\''"CCE-\1" not in foreman_params.policy_exemptions'\''\
&@
    # Swap the pattern space which includes our entire hold space plus modifications into the hold space. 
    x
    # Delete the pattern space and begin processing the next input. Note this section doesn not print and dump the hold space. Print only happens when tags are encountered or at the end.
    d
   }
  # We are processing an irrelevant line. Just add it to the hold space.
  H
  # If this is the end swap the hold space into the pattern space
  $x
  # Again if this is the end print out the remaining pattern space
  $p
  # Clean the pattern space and allow the program to complete
  d
}' $1 | sed $quiet_switch '{
 # This secondary script will use a standard N P D loop to deal with when lines with inline content inherited from the scap autogenerator.
 # It crudely assumes playbooks cobbled together by oscap xccdf generate are written in a specific way with a when section directly preceding the tags section
 # This is circumstantially nearly always as of when this was written so but may not always be. 
 # When such a when line from the autogenerator is encountered
 /^      when: .*$/{
    # Read a second line into the pattern buffer
    N
    # if a second when placed by the first sed program above just above the tags is spotted in the following line
    /\n      when:$/{
      # delete the second when line serving as a hash section header that has no inline when payload
      s/\n      when://
      # replace the first line reading when:payload with a new when section header, newline and the payload as the first hash member on the next line
      s/.*when:\(.*\)/      when:\
        -\1/
    }
  }
  # Print the first line of the pattern space:
  P
  # Clear the printed line from the pattern space and iterate with the next line of input
  D
}' 
