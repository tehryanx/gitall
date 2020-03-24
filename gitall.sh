#!/bin/bash

[[ $1 == "" ]] && { 
	echo "gitall orgname [--count] [--deep]"; 
	exit 1;
};

deep_flag=false;
count_flag=false;

while [ "$1" != "" ]; do
	[[ $1 =~ ^-c|--count$ ]] && { count_flag=true; shift 1; };
	[[ $1 =~ ^-d|--deep$ ]] && { deep_flag=true; shift 1; };
	[[ $1 != "" ]] && { target=$1; shift 1; };
done

apibase="https://api.github.com";

blue=`tput setaf 49`
pink=`tput setaf 198`
reset=`tput sgr0`
pr="${blue}->${reset}"

# get all repos from the org
echo "$pr Detecting repos for ${pink}$target${reset}";
org_repos=$(curl -s "$apibase/orgs/$target/repos" | jq -r '.[] | .html_url');
echo "$pr found ${pink}$(echo "$org_repos" |wc -l)${reset} repos";
if [[ $count_flag == false ]]; then
	mkdir $target; cd $target;
	for i in ${org_repos}; do
		echo "$pr Cloning ${pink}$i${reset}";
		git clone $i > /dev/null;
	done
	cd ..;
fi

if [[ $deep_flag == true ]]; then
	# get all members
	echo "$pr Detecting members for ${pink}$target${reset}";
	members=$(curl -s "$apibase/orgs/$target/members" | jq -r '.[] | .login');
	echo "$pr found ${pink}$(echo "$members" | wc -l)${reset} members";
	# get member repos
	for member in ${members}; do
		echo "$pr Detecting repos for ${pink}$member${reset}";
		member_repos=$(curl -s "$apibase/users/$member/repos" | jq -r '.[] | .html_url');
		echo "$pr found ${pink}$(echo "$member_repos" | wc -l)${reset} repos";
		if [[ $count_flag == false ]]; then
			mkdir $member; cd $member;
			for i in ${member_repos}; do
				echo "$pr Cloning ${pink}$i${reset}";
				git clone $i > /dev/null;
			done
			cd ..;
		fi
	done
fi
