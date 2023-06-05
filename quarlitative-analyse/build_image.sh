#!/bin/bash

log_path="`pwd`"
filename=docker_cleanup_$timestamp.log
log=$log_path/$filename
timestamp=$(date +%Y%m%d_%H%M%S)



docker_find (){
    echo "#####################################################################" >> $log
    echo "Finding syscall-test images" >> $log
    echo "#####################################################################" >> $log
    REMOVEIMAGES=`docker images | grep "syscall-test" | awk '{print $3}'`

    echo "Listing images that needs to be cleaned up" >> $log
    echo $REMOVEIMAGES >>$log
}


docker_cleanup(){
    echo "#####################################################################" >> $log
    echo "Cleaning images" >> $log
    echo "#####################################################################" >> $log
    docker rmi -f ${REMOVEIMAGES}
}


docker_space_after(){
    CURRENTSPACE=`docker system df`
    echo "Current Docker Space, after clean up:" >> $log
    echo $CURRENTSPACE >>$log
}


docker_space_before
docker_find
docker_cleanup
docker_space_after



# docker build -t  syscall-test .

# sudo docker tag syscall-test:latest yaoxinjing/syscall-test:latest
# sudo docker push yaoxinjing/syscall-test


# docker build -t  syscall-inteceptor-test .

# sudo docker tag  syscall-inteceptor-test:latest yaoxinjing/syscall-inteceptor-test:latest
# sudo docker push yaoxinjing/syscall-inteceptor-test

cargo build

docker build -t  qualitative_analyse_fake .

sudo docker tag  qualitative_analyse_fake:latest yaoxinjing/qualitative_analyse_fake:latest
sudo docker push yaoxinjing/qualitative_analyse_fake







