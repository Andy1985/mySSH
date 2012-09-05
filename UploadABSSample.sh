#/bin/bash

#---------------------------------------------------------------
_pwd=/home/dep/MailSampleUpload
files=/home/xmail/.bogofilter/t
CONF="${_pwd}/UploadTask.cf"
DATA="${_pwd}/data"
LOG="${_pwd}/log/UploadABSSample`date +'%Y%m%d'`.log"
ABS_TAG=42
remote_exec="${_pwd}/remote_exec.exp"
remote_cmd="/home/dep/MailSample/ABS42Classify.sh"

mkdir -v -p ${_pwd}/log
export NAME
export ID
export UPLOAD_BEGIN_TIME
export UPLOAD_TIME_LENTH
export UPLOAD_LOOP_TIME
export UPLOAD_IP
export UPLOAD_USER
export UPLOAD_PASSWORD
export UPLOAD_PATH

#---------------------------------------------------------------
__reset_config()
{
	NAME=""
	ID=""
	UPLOAD_BEGIN_TIME=""
	UPLOAD_TIME_LENTH=""
	UPLOAD_LOOP_TIME=""
	UPLOAD_IP=""
	UPLOAD_USER=""
	UPLOAD_PASSWORD=""
	UPLOAD_PATH=""
}

__print_conf()
{
	echo "==================$NAME===================="
	echo "NAME:			$NAME"
	echo "ID:			$ID"
	echo "UPLOAD_BEGIN_TIME:	$UPLOAD_BEGIN_TIME"
	echo "UPLOAD_TIME_LENTH:	$UPLOAD_TIME_LENTH"
	echo "UPLOAD_LOOP_TIME:	$UPLOAD_LOOP_TIME"
	echo "UPLOAD_IP:		$UPLOAD_IP"
	echo "UPLOAD_USER:		$UPLOAD_USER"
	echo "UPLOAD_PASSWORD:	$UPLOAD_PASSWORD"
	echo "UPLOAD_PATH:		$UPLOAD_PATH"
}

__get_value()
{
	echo $@|awk -F '= ' '{print $2}'|awk 'gsub(/^ *| *$/,"")'
}

__strcmp()
{
	echo "$1" |grep "$2" >/dev/null
	
	if [ $? -eq 0 ];then
		echo 0;
	else
		echo 1;
	fi
}

__load_config()
{
	start=0 
	end=0

	__reset_config
	NAME="$1"

	grep -r "\[$NAME\]" $CONF >/dev/null
	[ $? -ne 0 ] && { echo "No $NAME config"; return 1; }

	while read line
	do
		[ `__strcmp "$line" "^#"` -eq 0 ] && continue
		[ `__strcmp "$line" "^$"` -eq 0 ] && continue
		
		[ `__strcmp "$line" "\[$NAME\]"` -eq 0 ] && { start=1; continue; }
		[ `__strcmp "$line" "\[*\]"` -eq 0 ] && [ $start -eq 1 ] && { end=1; break; }

		if [ $start -eq 1 -a $end -ne 1 ];then
			[ `__strcmp "$line" "ID"` -eq 0 ] && ID=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_BEGIN_TIME"` -eq 0 ] && UPLOAD_BEGIN_TIME=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_TIME_LENTH"` -eq 0 ] && UPLOAD_TIME_LENTH=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_LOOP_TIME"` -eq 0 ] && UPLOAD_LOOP_TIME=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_IP"` -eq 0 ] && UPLOAD_IP=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_USER"` -eq 0 ] && UPLOAD_USER=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_PASSWORD"` -eq 0 ] && UPLOAD_PASSWORD=`__get_value $line`
			[ `__strcmp "$line" "UPLOAD_PATH"` -eq 0 ] && UPLOAD_PATH=`__get_value $line`
		fi

	done < $CONF

	return 0
}


__list_name()
{
	while read line
	do
		[ `__strcmp "$line" "^#"` -eq 0 ] && continue
		[ `__strcmp "$line" "^$"` -eq 0 ] && continue
		
		[ `__strcmp "$line" "\[*\]"` -eq 0 ] && echo $line|awk 'gsub(/\[|\]/,"")' 
	done < $CONF
}

__upload()
{
	UPLOAD_PATH="$UPLOAD_PATH/`date +'%Y%m%d'`/${ABS_TAG}"
	#exec ${_pwd}/TransferMail.exp $UPLOAD_IP $UPLOAD_USER $UPLOAD_PASSWORD $1 $UPLOAD_PATH
	${remote_exec} "/usr/local/bin/scp $1 $UPLOAD_USER@$UPLOAD_IP:$UPLOAD_PATH" "$UPLOAD_PASSWORD"
	${remote_exec} "/usr/local/bin/scp $1 dep@192.168.165.126:$UPLOAD_PATH" "vparaM1itqvay6R="
}

__get_name_upload()
{
	_now=`date +'%H'`

	for name in `__list_name`
	do
		__load_config $name
		_start=`echo $UPLOAD_BEGIN_TIME|awk -F ':' '{print $1}'`
		_end=`expr $_start + $UPLOAD_TIME_LENTH`

		if [ $_end -lt 24 ];then
			if [ ${_now} -ge ${_start} -a ${_now} -lt ${_end} ];then
				return
			fi
		else
			if [ ${_now} -ge ${_start} -a ${_now} -lt 24 ] || \
			[ ${_now} -ge 0 -a ${_now} -lt `expr ${_end} - 24` ];then
				return
			fi
		fi
	done
}

#---------------------------------------------------------------
echo "[`date +'%H:%M:%S'`] [UploadABSSample] [start]" >>${LOG}
__get_name_upload >>${LOG} 2>&1
file=`date +'%Y%m%d%H' --date '1 hour ago'`
cd $files && tar zcf ${DATA}/abs${ABS_TAG}-${file}.tgz *${file}* >>${LOG} 2>&1
if [ $? -eq 0 ];then
	__upload ${DATA}/abs${ABS_TAG}-${file}.tgz >>${LOG} 2>&1
	${remote_exec} "/usr/local/bin/ssh $UPLOAD_USER@$UPLOAD_IP ${remote_cmd} $NAME" "$UPLOAD_PASSWORD" >>${LOG} 2>&1
	${remote_exec} "/usr/local/bin/ssh dep@192.168.165.126 ${remote_cmd} $NAME" "vparaM1itqvay6R=" >>${LOG} 2>&1
fi
echo "[`date +'%H:%M:%S'`] [UploadABSSample] [finish]" >>${LOG}
