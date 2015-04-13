#!/usr/bin/env bash

USER=${USER:smli}
usr_ssh="/backup/home/$USER/.ssh" #~/.ssh
id_pr_key="$usr_ssh/id_rsa"
id_pu_key="$usr_ssh/id_rsa.pub"

node_ln=($(grep -E 'node[1-9].*-ib' /etc/hosts |awk '{print $1":::"$2}'))
node_ln+=($(grep manager-ib /etc/hosts |awk '{print $1":::"$2}'))

nodes=()
loc_node=$(hostname)

# ssh copy id
# nodes share /dev/pfs2 --> $usr_ssh
sed -i "s|.*$(awk '{print $2}' $usr_ssh/id_rsa.pub).*||;/^$/d" $usr_ssh/authorized_keys
cat $id_pu_key >> $usr_ssh/authorized_keys

# known_hosts fingerprint(yes/no)
echo "Input your password: "
read -s PASSWD
apswd=autopswd.$(mktemp -u|sed 's/.*\.//')
cat > $apswd <<EOF
#!/usr/bin/expect
set timeout 3
spawn /usr/bin/ssh %%HOST%% "export HOME=/backup/home/$USER;cd;echo LS0tYWRkLS0tCg==|base64 -d"
expect {
"(yes/no)" { send "yes\r"; exp_continue }
"password:" { send "$PASSWD\r" }
}
expect "*"
send "exit\r"
expect eof
EOF

for line in ${node_ln[@]}; do
    name=${line##*:::}
    ip_a=${line%%:::*}
    if ping $ip_a -c1 2>&1 >/dev/null; then
        nodes+=(${name})
        echo "==> ${name}: ${ip_a}. Yes."
        #ssh -o StrictHostKeyChecking=no $USER@$name "echo -\> add."
        sed -i "s|%%HOST%%|$name|" $apswd
        expect -f $apswd
        sed -i "s|$name|%%HOST%%|" $apswd
    else
        echo "==> $name unreachable"
    fi
    echo
done
rm $apswd
echo "==> ${#nodes[@]} nodes added. They are:"
#echo " -> ${nodes[@]}"
awk '{print $1}' $usr_ssh/known_hosts
