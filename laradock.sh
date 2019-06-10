#!/bin/bash

if [ -z "$1" ]; then
    echo "Laradock: debe de especificar una acción"
else
    if [ "$1" == "install" ]; then
        sudo cp $LARADOCKFOLDER/laradock.sh /usr/local/bin/laradock
    elif [ "$1" == "up" ]; then
        cd $LARADOCKFOLDER && docker-compose up -d nginx mysql redis phpmyadmin
    elif [ "$1" == "run" ]; then                
        if [ -z "$2" ]; then
            echo "Laradock: debe de especificar un contenedor"
        else
            shift # quitando el primer parametro
            cd $LARADOCKFOLDER && docker-compose up -d ${@}
        fi
    elif [ "$1" == "build" ]; then                
        if [ -z "$2" ]; then
            echo "Laradock: debe de especificar un contenedor"
        else
            shift # quitando el primer parametro
            cd $LARADOCKFOLDER && docker-compose build ${@}
        fi
    elif [ "$1" == "down" ]; then
        cd $LARADOCKFOLDER && docker-compose down
    elif [ "$1" == "restart" ]; then
        cd $LARADOCKFOLDER && docker-compose down && docker-compose up -d nginx mysql redis phpmyadmin
        #cd $LARADOCKFOLDER && docker-compose restart -t 0 nginx mysql phpmyadmin
    elif [ "$1" == "status" ]; then
        cd $LARADOCKFOLDER && docker-compose ps
    elif [ "$1" == "workspace" ]; then
        if [ -z "$2" ]; then
            cd $LARADOCKFOLDER && docker-compose exec --user=laradock workspace bash
        else
            user="$2"
            cd $LARADOCKFOLDER && docker-compose exec --user="$user" workspace bash
        fi
    elif [ "$1" == "reload-db" ]; then
        cd $LARADOCKFOLDER && docker-compose exec mysql bash -c "mysql -u root -p < /docker-entrypoint-initdb.d/createdb.sql"
    elif [ "$1" == "add-db" ]; then
        if [ -z "$2" ]; then
            echo "Laradock: debe de especificar un nombre para la bd"
        else
            dbname="$2"
            dfile="createdb.sql"
            dfiletmp="createdb.sql.tmp"
            cdb=$"CREATE DATABASE IF NOT EXISTS $dbname COLLATE 'utf8_general_ci' ;\nGRANT ALL ON $dbname.* TO 'default'@'%' ;\n\nFLUSH PRIVILEGES ;"

            cd $LARADOCKFOLDER &&
            cd mysql/docker-entrypoint-initdb.d &&
            cp $dfile $dfiletmp &&
            rm $dfile &&
            sed "s#FLUSH PRIVILEGES ;#$cdb#g" "$dfiletmp" > "$dfile" &&
            rm $dfiletmp
            cd $LARADOCKFOLDER && docker-compose exec mysql bash -c "mysql -u root -p < /docker-entrypoint-initdb.d/createdb.sql" 
        fi
    elif [ "$1" == "add-site" ]; then                
        if [ -z "$2" ]; then
            echo "Laradock: debe de especificar un dominio"
        else
            dconf="laravel.conf.example"
            conf="$2.conf"
            site="$2.test"
            dfolder="/var/www/laravel/public"
            folder="/var/www/$2/public"

            cd $LARADOCKFOLDER &&
            cd nginx/sites &&
            sed "s#laravel.test#$site#g; s#$dfolder#$folder#g" "$dconf" > "$conf" &&
            cd $LARADOCKFOLDER && docker-compose restart -t 0 nginx mysql phpmyadmin &&
            echo "127.0.0.1  $site" | sudo tee --append /etc/hosts
        fi
    else
        echo "Laradock: no existe dicha acción"
    fi
fi
