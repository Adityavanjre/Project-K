# 触发对 features.yml 的检查
set -e
set -x

rootPath=$(git rev-parse --show-toplevel)
source $rootPath/utils/common-source.sh

ruby ./validate_yaml.rb || report --error_level 0 --error_type 0 --reason "Feature Toggle 检查失败"