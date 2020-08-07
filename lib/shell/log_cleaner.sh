# 0 0 1 * * /opt/rails-app/slime_crm/lib/shell/log_cleaner.sh >> /opt/rails-app/slime_crm/log/log_cleaner.log 2>&1

echo "============================================="
echo "`date +"%F %T"` -- running log_cleaner.sh"

log_dir="/opt/rails-app/slime_crm_hf/log"
log_backup="production.log.backup_`date +"%y%m%d"`"
cd $log_dir
echo ">> cd $log_dir"
mv production.log $log_backup
echo ">> mv production.log $log_backup"
touch production.log
echo ">> touch production.log"
gzip $log_backup
echo ">> gzip $log_backup"
echo "finished!"




