#!/bin/bash

get_id() {
    # Get id and name
    ID=`sed '/^ID=/!d;s/.*=//' $MYINFO_FILE`
    NAME=`sed '/^Name=/!d;s/.*=//' $MYINFO_FILE`
    if [[ ${#ID} -le 7 ]]; then
        echo "Please fill your information in myinfo.txt!!!"
        exit 1
    fi
    ID="${ID##*\r}"
}

copy_v_file() {
    if [[ ! -f $OSCPU_PATH/soc/vsrc/${1} ]]; then
        printf "Please place \e[1;31m%s\e[0m in \e[1;31m%s\e[0m.\n" ${1} $OSCPU_PATH/soc/vsrc/
        exit 1
    fi
    cp $OSCPU_PATH/soc/vsrc/${1} $SUBMIT_FLODER/
}

check_file() {
    if [[ ! -f $SUBMIT_HOME/${1} ]]; then
        printf "Please place \e[1;31m%s\e[0m in \e[1;31m%s\e[0m.\n" ${1} $OSCPU_PATH/$SUBMIT_FLODER
        exit 1
    fi
}

cpu_check() {
    cd $SUBMIT_HOME
    OUTPUT=$(echo ${ID:0-4} | python3 $OSCPU_PATH/soc/cpu-check.py)
    if [[ ! $OUTPUT =~ "Your core is fine in module name and signal interface" ]]; then
        printf "Failed to check your module name and signal interface!!! Please modify your code according to the requirements in \e[1;31mhttps://github.com/OSCPU/ysyxSoC\e[0m.\n"
        exit 1
    fi
    rm cpu-check.log
    cd $OSCPU_PATH
}

get_default_url() {
    git remote -v | while read line; do
        if [[ $line =~ "origin" ]] && [[ $line =~ "push" ]]; then
            echo $1
            echo $line | grep -o '\ .*\ '
            return
        fi
    done
}

push_repo() {
    URL="$(get_default_url $1)"

    printf "Enter a new URL to replace the default push URL(\e[1;34m%s\e[0m) or leave a blank to skip.\n" $URL
    read -p "Enter your new push URL: " -e INPUT
    if [[ -n "$INPUT" ]] && [[ ! $INPUT == $URL ]]; then
        git remote set-url --push origin $INPUT
    else
        INPUT=$URL
    fi
    
    git add .
    git commit -m "dc & vcs" --no-verify --allow-empty 1>/dev/null 2>&1

    git push gitee
    if [ $? -ne 0 ]; then
        printf "\e[1;31mFailed to push!!!\e[0m\n"
        exit 1
    fi

    printf "You repo has been pushed to \e[1;32m%s\e[0m.\n" $INPUT
}


OSCPU_PATH=$(dirname $(readlink -f "$0"))
SUBMIT_FLODER="submit"
SUBMIT_HOME=$OSCPU_PATH/$SUBMIT_FLODER
WARNGING_FILE="Verilator中Warning无法清理说明.xlsx"
MYINFO_FILE=$OSCPU_PATH"/myinfo.txt"

get_id
printf "Read ID \e[1;32m%s\e[0m from myinfo.txt\n" $ID

PREFIX="ysyx_${ID:0-6}"
V_FILE=$PREFIX".v"
PDF_FILE=$PREFIX".pdf"

check_file "rtthread-loader.png"
check_file $WARNGING_FILE
check_file $PREFIX".pdf"
copy_v_file $PREFIX".v"

cpu_check
# push_repo
