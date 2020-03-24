#!/bin/bash

[[ $1 == "" ]] && { 
	echo "gitall orgname [--count] [--deep] [--user] [--pass]"; 
	exit 1;
};

deep_flag=false;
count_flag=false;

while [ "$1" != "" ]; do
	[[ $1 =~ ^-c|--count$ ]] && { count_flag=true; shift 1; continue;};
	[[ $1 =~ ^-d|--deep$ ]] && { deep_flag=true; shift 1; continue;};
	[[ $1 =~ ^-u|--user$ ]] && { username=$2; shift 2; continue;};
	[[ $1 =~ ^-p|--pass$ ]] && { password=$2; shift 2; continue;};
	[[ $1 != "" ]] && { target=$1; shift 1; };

done


apibase="https://api.github.com";
[[ $username != "" && $password != "" ]] && { apibase="https://$username:$password@api.github.com"; };
first_try=$(curl -s $apibase/orgs/$target/repos?page=1 | jq -r '.[]')
[[ ${first_try:0:8} == "API rate" ]] && { echo "Rate limit exceeded, authenticated accounts have higher limits, use -u and -p to auth."; exit 1; };
[[ ${first_try:0:3} == "Bad" ]] && { echo "Authentication failed."; exit 1; };

blue=`tput setaf 49`
pink=`tput setaf 198`
reset=`tput sgr0`
pr="${blue}->${reset}"

# get all repos from the org
echo "$pr Detecting repos for ${pink}$target${reset}";
org_repos="";
page=1;

while [ "$(curl -s $apibase/orgs/$target/repos?page=$page | jq -c '.')" != "[]" ]; do 
	org_repos="$org_repos $(curl -s "$apibase/orgs/$target/repos?page=$page" | jq -r '.[] | .html_url')";
	page=$((page+1))
done
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
	members=""
	page=1
	while [ "$(curl -s $apibase/orgs/$target/members?page=$page | jq -c '.')" != "[]" ]; do
		members="$members $(curl -s "$apibase/orgs/$target/members?page=$page" | jq -r '.[] | .login')";
		page=$((page+1));
	done
	echo "$pr found ${pink}$(echo "$members" | wc -l)${reset} members";
	# get member repos
	for member in ${members}; do
		echo "$pr Detecting repos for ${pink}$member${reset}";
		member_repos=""
		page=1
		while [ "$(curl -s $apibase/users/$member/repos?page=$page | jq -c '.')" != "[]" ]; do
			member_repos="$member_repos $(curl -s "$apibase/users/$member/repos?page=$page" | jq -r '.[] | .html_url')";
			page=$((page+1));
		done
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
