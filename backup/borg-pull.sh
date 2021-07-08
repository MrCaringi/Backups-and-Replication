borgs@borg-server$ (
  eval $(ssh-agent) > /dev/null
  ssh-add -q ~/.ssh/id_rsa.pub
  echo 'borgcuidamisdatosAS6212RD-MXMX' | \
    ssh -A -o StrictHostKeyChecking=no borgc@borg-client "BORG_PASSPHRASE=\$(cat) borg --rsh 'ssh -o StrictHostKeyChecking=no' init --encryption repokey ssh://borgs@borg-server/~/repo"
  kill "${SSH_AGENT_PID}"
)

borgcuidamisdatosAS6212RD-MXMX


borg create --stats --list --filter=E --compression auto,lzma,9 ${FULLREP} ${ORI} 2>&1

 (
  eval $(ssh-agent) > /dev/null
  ssh-add -q ~/.ssh/id_rsa.pub
  echo 'borgcuidamisdatosAS6212RD-MXMX' | \
    ssh -A -o StrictHostKeyChecking=no jfc@192.168.100.50 "BORG_PASSPHRASE=\$(cat) borg --rsh 'ssh -o StrictHostKeyChecking=no' init --encryption repokey ssh://borgs@borg-server/~/repo"
  kill "${SSH_AGENT_PID}"
)