NODE=$(hostname -s)
declare -a arr=("data02" "data01")

rm test-jonas.fio

cat > test-jonas.fio <<-EOF
[global]
ioengine=libaio
thread
direct=1
rw=write
size=10000m
iodepth=8
group_reporting=1


EOF

for vpool in "${arr[@]}"; do for i in {1..16}; do echo "[worker_${vpool}_${i}]" >> test-jonas.fio; echo "filename=/mnt/${vpool}/${NODE}/volume-${i}.raw" >> test-jonas.fio; echo "" >> test-jonas.fio; done; done
