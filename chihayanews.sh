#!/bin/bash
## 参考
# http://needtec.exblog.jp/21547762/
# https://gist.github.com/sabaneko/7132133
# http://www.garunimo.com/program/linux/linux40.xhtml
# http://www.slideshare.net/masahiroh1/ss-24757915
#
# http://uzulla.hateblo.jp/entry/2014/04/11/224459
# http://nanoway.net/web/nicovideo-comment-api
# http://dic.nicovideo.jp/a/ニコニコ動画api

cache_dir=$(echo ~/.chihayanews.d)

usage() {
	echo "Usage: $(basename $0) [-l|--login]"
}

login() {
	if [ -z "$SH_CHYNS_MAIL" ]; then
		SH_CHYNS_MAIL=$(sed -n 1p ~/.chihayanews)
	fi
	if [ -z "$SH_CHYNS_PW" ]; then
		SH_CHYNS_PW=$(sed -n 2p ~/.chihayanews)
	fi
	wget --post-data "mail=${SH_CHYNS_MAIL}&password=${SH_CHYNS_PW}" -q -O - --save-cookies=${cache_dir}/cookie1.txt --keep-session-cookies https://secure.nicovideo.jp/secure/login?site=niconico > /dev/null
	wget --save-cookies=${cache_dir}/cookie2.txt --keep-session-cookies -q -O - --load-cookies=${cache_dir}/cookie1.txt http://flapi.nicovideo.jp/api/getflv/sm4538955 | tr = @ | tr % = | nkf -WwmQ | tr @ = | sed 's/&/\n/g' > ${cache_dir}/decoded.txt
}

main() {
	if [ ! -f ${cache_dir}/decoded.txt ]; then
		login
	fi

	thread_id=$(grep '^thread_id=' ${cache_dir}/decoded.txt | cut -d'=' -f2)
	ms=$(grep '^ms=' ${cache_dir}/decoded.txt | cut -d'=' -f2)
	user_id=$(grep '^user_id=' ${cache_dir}/decoded.txt | cut -d'=' -f2)

	## threadkey=""(空) と force_184="1" は、変わらないようなので
	## とりあえず、getthreadkeyの取得とパースは行わない
	# wget --save-cookies=${cache_dir}/cookie3.txt --keep-session-cookies -q -O - --load-cookies=${cache_dir}/cookie1.txt http://flapi.nicovideo.jp/api/getthreadkey?thread=${thread_id} > ${cache_dir}/getthreadkey.html

	wget --post-data "<thread thread=\"${thread_id}\" version=\"20090904\" res_from=\"-1000\" scores=\"1\" nicoru=\"1\" threadkey=\"\" force_184=\"1\" user_id=\"${user_id}\" />" -q -O - --save-cookies=${cache_dir}/cookie1.txt --keep-session-cookies ${ms} > ${cache_dir}/ms.html

	sed 's/<\/chat>/\n/g' ${cache_dir}/ms.html | sed 's/<chat /\n/g' | sed 's/>/ /g' | sed '/^ *$/d' | tail -n +2 | head -n -1 > ${cache_dir}/notag.txt

	awk 'BEGIN{FS=" ";OFS=","}{print $3,$NF}' ${cache_dir}/notag.txt | cut -c7- | tr -d '"' | awk 'BEGIN{FS=","}{if($1 < 2000){print $2}}' > ${cache_dir}/chihayanews.txt

	tail -n 1 ${cache_dir}/chihayanews.txt
}

if [ $# -gt 1 ]; then
	usage
	exit 1
fi
if [ -n ${cache_dir} ]; then
	if [ ! -d ${cache_dir} ]; then
		mkdir ${cache_dir}
	fi
else
	cache_dir=''
fi
if [ -n "$1" ]; then
	case "$1" in
	'-l'|'--login')
		login
		;;
	* )
		usage
		exit 1
		;;
	esac
fi

main
