complete -c tunet-bash -s c -l config -d 'Specify username and password for account in use'
complete -c tunet-bash -s i -l login -d 'Make login request'
complete -c tunet-bash -s o -l logout -d 'Make logout request'
complete -c tunet-bash -s w -l whoami -d 'Make a status query of account currently online'
complete -c tunet-bash -s v -l verbose -d 'When used with whoami query, provides detailed account statistics'
complete -c tunet-bash -l pass -d 'When used with config, set pass-name instead of password' -r --no-files
complete -c tunet-bash -s a -l auth -d 'Auth method' --no-files -ra '4 6 auto either'
complete -c tunet-bash -l version -d 'Print version'
