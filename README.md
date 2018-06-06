# granular-scap-ansible-control-for-foreman

This is a script written to allow two foreman parameters set for all hosts in a server fleet via hostgroup or overridden host parameters to exempt systems from specific scap controls 
with a CCE tag, without fragmenting the job template in Ansible Tower into multiple differently parameterized templates.
A single template running all SCAP controls can run on the entire fleet.  

This script and its sed programs inject a "when" yml section into each play. 
The section is a multi-line hash of conditions governing each play.
The first hash member sets a requirement that foreman_params.policies include the policy name. 
In sections where a tag named CCE-<number> is mentioned, a second when hash member is inserted requiring that this CCE number IS NOT in foreman_params.policy_exemptions hash

